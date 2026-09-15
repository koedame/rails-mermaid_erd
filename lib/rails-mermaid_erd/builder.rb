class RailsMermaidErd::Builder
  # The order associations are read in, which is also the order their labels
  # appear in a relation's comment.
  RELATION_MACROS = [:has_many, :has_and_belongs_to_many, :belongs_to, :has_one].freeze

  class << self
    def model_data
      result = {
        Models: [],
        Relations: []
      }

      ::Rails.application.eager_load!

      # Compile each `ignore_tables` entry once. Wrap `RegexpError` so the
      # rake-task output names the offending YAML entry rather than just the
      # underlying parser message.
      ignore_patterns = RailsMermaidErd.configuration.ignore_tables.map do |pattern|
        Regexp.new(pattern)
      rescue RegexpError => e
        raise ArgumentError, "config/mermaid_erd.yml: invalid `ignore_tables` pattern #{pattern.inspect}: #{e.message}"
      end

      # Class names whose `table_name` matches an ignore pattern. Resolved
      # *before* the main loop so we can also drop outgoing reflections that
      # point at an ignored model — otherwise the diagram would render orphan
      # nodes for the ignored tables. A Hash gives O(1) `key?` lookups without
      # pulling in `set` (which is autoloaded on Ruby 3.2+ but not earlier).
      ignored_model_names = compute_ignored_model_names(ignore_patterns)

      # Single table inheritance subclasses share their base class's table, so
      # each hierarchy is drawn as the base class's entity. Associations that
      # target a subclass are pointed at that entity too.
      sti_base_names = compute_sti_base_names

      # Associations grouped by the link they describe (see `link_key`). Each
      # group becomes one relation line once every model has been read.
      links = Hash.new { |hash, key| hash[key] = [] }

      ::ActiveRecord::Base.descendants.sort_by(&:name).each do |defined_model|
        next unless defined_model.table_exists?
        next if defined_model.name.include?("HABTM_")
        next if defined_model.table_name.blank?
        next if sti_base_names.key?(defined_model.name)
        next if ignored_model_names.key?(defined_model.name)

        table_name = defined_model.table_name
        model = {
          TableName: table_name,
          TableComment: ::ActiveRecord::Base.connection.table_comment(table_name.to_sym) || "",
          ModelName: defined_model.name,
          IsModelExist: true,
          Columns: []
        }

        foreign_keys = ::ActiveRecord::Schema.foreign_keys(defined_model.table_name).map { |k| k.options[:column] }
        primary_key = defined_model.primary_key
        defined_model.columns.each do |column|
          key = ""
          if column.name == primary_key
            key = "PK"
          elsif foreign_keys.include?(column.name)
            key = "FK"
          end
          model[:Columns] << {
            name: column.name,
            type: column.type,
            key: key,
            comment: column.comment
          }
        end

        result[:Models] << model

        hierarchy = [defined_model] + defined_model.descendants
          .select { |descendant| sti_base_names[descendant.name] == defined_model.name }
          .sort_by(&:name)

        RELATION_MACROS.each do |macro|
          hierarchy_reflections(hierarchy, macro, sti_base_names).each do |reflection, reflection_model_name|
            # Polymorphic `belongs_to` has no concrete target class — the target is
            # decided at row level by the `*_type` column. Emitting an edge to the
            # macro name (e.g. `"Imageable"`) would render an orphan node with no
            # columns; the polymorphic parents express the relationship via their
            # `has_many ..., as: :foo` reflections instead.
            next if macro == :belongs_to && reflection.polymorphic?

            next if ignored_model_names.key?(reflection_model_name)

            association = {owner: model[:ModelName], macro: macro, reflection: reflection, target: reflection_model_name}
            links[link_key(association)] << association
          end
        end
      end

      result[:Relations] = links.map { |key, associations| relation_for(key, associations) }

      result
    end

    # Returns a Hash keyed by class names whose underlying table matches an
    # entry from `ignore_tables`. Mirrors the guard rails on the main loop
    # (`table_exists?`, HABTM scaffolding, blank `table_name`) so that adding
    # an `ignore_tables` entry can't crash the rake task on hosts with
    # abstract STI bases or descendants whose backing table isn't created yet.
    def compute_ignored_model_names(ignore_patterns)
      return {} if ignore_patterns.empty?

      ::ActiveRecord::Base.descendants.each_with_object({}) do |defined_model, acc|
        next unless defined_model.table_exists?
        next if defined_model.name.include?("HABTM_")
        table_name = defined_model.table_name
        next if table_name.blank?
        acc[defined_model.name] = true if ignore_patterns.any? { |pattern| pattern.match?(table_name) }
      end
    end

    # Returns a Hash mapping each single table inheritance subclass name to its
    # base class name. A subclass that sets its own `table_name` keeps its own
    # entity, since it no longer shares the base class's table.
    def compute_sti_base_names
      ::ActiveRecord::Base.descendants.each_with_object({}) do |defined_model, acc|
        next unless defined_model.table_exists?
        next if defined_model.name.include?("HABTM_")
        base_class = defined_model.base_class
        next if base_class == defined_model
        next unless base_class.table_name == defined_model.table_name
        acc[defined_model.name] = base_class.name
      end
    end

    # Returns `[reflection, target model name]` pairs for the associations
    # declared anywhere in an inheritance hierarchy, with targets resolved to
    # their base class. A subclass inherits its base class's reflections, so
    # pairs repeating a name and target are dropped rather than drawn twice.
    def hierarchy_reflections(hierarchy, macro, sti_base_names)
      hierarchy
        .flat_map { |model| model.reflect_on_all_associations(macro) }
        .map { |reflection|
          model_name = get_reflection_model_name(reflection)
          [reflection, sti_base_names.fetch(model_name, model_name)]
        }
        .uniq { |reflection, model_name| [reflection.name, model_name] }
    end

    # Identifies the link between two tables that an association describes, so
    # that every association describing the same link is drawn as one line —
    # whichever model declares it and whichever model sorts first — and
    # associations describing different links are never folded together:
    #
    # - A foreign key column is one link: `belongs_to` on the model that holds
    #   the column, `has_many` / `has_one` on the model it references.
    # - A join table is one link: both sides of `has_and_belongs_to_many`.
    # - A `:through` association derives from other links and stores nothing
    #   of its own, so it is identified by the two models it connects.
    def link_key(association)
      owner, target, reflection = association.values_at(:owner, :target, :reflection)

      if reflection.options[:through]
        [:through, *[owner, target].sort]
      elsif association[:macro] == :has_and_belongs_to_many
        [:join_table, reflection.join_table.to_s, *[owner, target].sort]
      elsif association[:macro] == :belongs_to
        [:foreign_key, owner, foreign_key_columns(reflection), target]
      else
        [:foreign_key, target, foreign_key_columns(reflection), owner]
      end
    end

    # Builds the relation line for one link from every association that
    # describes it, so no glyph depends on the order they were read in.
    def relation_for(key, associations)
      case key.first
      when :foreign_key
        _, child, _, parent = key
        macros = associations.map { |association| association[:macro] }
        optional = associations.any? { |association| association[:macro] == :belongs_to && optional_belongs_to?(association[:reflection]) }
        {
          LeftModelName: parent,
          LeftValue: optional ? "|o" : "||",
          Line: "--",
          RightModelName: child,
          RightValue: (macros.include?(:has_one) && !macros.include?(:has_many)) ? "o|" : "o{",
          Comment: association_labels(associations)
        }
      when :join_table
        _, _, left, right = key
        {LeftModelName: left, LeftValue: "}o", Line: "..", RightModelName: right, RightValue: "o{", Comment: "HABTM"}
      when :through
        _, left, right = key
        # Each end is "at most one" only when every association reaching that
        # end is a `has_one :through`.
        at_most_one = lambda do |model_name|
          reaching = associations.select { |association| association[:target] == model_name }
          reaching.any? && reaching.all? { |association| association[:macro] == :has_one }
        end
        {
          LeftModelName: left,
          LeftValue: at_most_one.call(left) ? "|o" : "}o",
          Line: "..",
          RightModelName: right,
          RightValue: at_most_one.call(right) ? "o|" : "o{",
          Comment: association_labels(associations)
        }
      end
    end

    def association_labels(associations)
      associations.map { |association|
        reflection = association[:reflection]
        prefix = {has_many: "HM", has_one: "HO", belongs_to: "BT"}.fetch(association[:macro])
        prefix = "#{prefix}T" if reflection.options[:through]
        "#{prefix}:#{reflection.name}"
      }.join(", ")
    end

    # Rails may hand back a String or a Symbol, or an Array for a composite key.
    def foreign_key_columns(reflection)
      Array(reflection.foreign_key).map(&:to_s)
    end

    def optional_belongs_to?(reflection)
      if ::Rails.application.config.active_record.belongs_to_required_by_default
        reflection.options[:optional]
      else
        !reflection.options[:required]
      end
    end

    # Doc: https://guides.rubyonrails.org/association_basics.html
    def get_reflection_model_name(reflection)
      if reflection.options[:class_name]
        reflection.options[:class_name].to_s.classify
      elsif reflection.options[:through]
        # `:source_type` is the authoritative class hint for a polymorphic
        # `:source`, so it takes precedence over `:source` when both are set.
        if reflection.options[:source_type]
          reflection.options[:source_type].to_s.classify
        elsif reflection.options[:source]
          reflection.options[:source].to_s.classify
        elsif reflection.source_reflection.nil?
          # `:through` targets a polymorphic `belongs_to` without `:source_type`;
          # Rails can't resolve a single class. Fall back to its `:source` default.
          reflection.name.to_s.classify
        else
          reflection.class_name
        end
      else
        reflection.class_name
      end
    end
  end
end
