class RailsMermaidErd::Builder
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

        hierarchy_reflections(hierarchy, :has_many, sti_base_names).each do |reflection, reflection_model_name|
          next if ignored_model_names.key?(reflection_model_name)

          reverse_relation = result[:Relations].find { |r|
            if reflection.options[:through]
              r[:RightModelName] == model[:ModelName] && r[:LeftModelName] == reflection_model_name && r[:Line] == ".."
            else
              r[:RightModelName] == model[:ModelName] && r[:LeftModelName] == reflection_model_name && r[:Line] == "--"
            end
          }
          if reverse_relation
            reverse_relation[:Comment] = if reflection.options[:through]
              "#{reverse_relation[:Comment]}, HMT:#{reflection.name}"
            else
              "#{reverse_relation[:Comment]}, HM:#{reflection.name}"
            end
          else
            result[:Relations] << {
              LeftModelName: model[:ModelName],
              LeftValue: reflection.options[:through] ? "}o" : "||",
              Line: reflection.options[:through] ? ".." : "--",
              RightModelName: reflection_model_name,
              RightValue: "o{",
              Comment: reflection.options[:through] ? "HMT:#{reflection.name}" : "HM:#{reflection.name}"
            }
          end
        end

        hierarchy_reflections(hierarchy, :has_and_belongs_to_many, sti_base_names).each do |reflection, reflection_model_name|
          next if ignored_model_names.key?(reflection_model_name)

          reverse_relation = result[:Relations].find { |r| r[:RightModelName] == model[:ModelName] && r[:LeftModelName] == reflection_model_name }
          if reverse_relation
            reverse_relation[:Comment] = "HABTM"
          else
            result[:Relations] << {
              LeftModelName: model[:ModelName],
              LeftValue: "}o",
              Line: "..",
              RightModelName: reflection_model_name,
              RightValue: "o{",
              Comment: "HABTM"
            }
          end
        end

        hierarchy_reflections(hierarchy, :belongs_to, sti_base_names).each do |reflection, reflection_model_name|
          # Polymorphic `belongs_to` has no concrete target class — the target is
          # decided at row level by the `*_type` column. Emitting an edge to the
          # macro name (e.g. `"Imageable"`) would render an orphan node with no
          # columns; the polymorphic parents express the relationship via their
          # `has_many ..., as: :foo` reflections instead.
          next if reflection.polymorphic?

          next if ignored_model_names.key?(reflection_model_name)

          reverse_relation = result[:Relations].find { |r| r[:RightModelName] == model[:ModelName] && r[:LeftModelName] == reflection_model_name }
          if reverse_relation
            if (::Rails.application.config.active_record.belongs_to_required_by_default && reflection.options[:optional]) || (!::Rails.application.config.active_record.belongs_to_required_by_default && !reflection.options[:required])
              reverse_relation[:LeftValue] = "|o"
            end
            reverse_relation[:Comment] = "#{reverse_relation[:Comment]}, BT:#{reflection.name}"
          else
            right_value = if (::Rails.application.config.active_record.belongs_to_required_by_default && reflection.options[:optional]) || (!::Rails.application.config.active_record.belongs_to_required_by_default && !reflection.options[:required])
              "o|"
            else
              "||"
            end
            result[:Relations] << {
              LeftModelName: model[:ModelName],
              LeftValue: "}o",
              Line: "--",
              RightModelName: reflection_model_name,
              RightValue: right_value,
              Comment: "BT:#{reflection.name}"
            }
          end
        end

        hierarchy_reflections(hierarchy, :has_one, sti_base_names).each do |reflection, reflection_model_name|
          next if ignored_model_names.key?(reflection_model_name)

          reverse_relation = result[:Relations].find { |r|
            if reflection.options[:through]
              r[:RightModelName] == model[:ModelName] && r[:LeftModelName] == reflection_model_name && r[:Line] == ".."
            else
              r[:RightModelName] == model[:ModelName] && r[:LeftModelName] == reflection_model_name && r[:Line] == "--"
            end
          }
          if reverse_relation
            reverse_relation[:LeftValue] = "|o"
            reverse_relation[:Comment] = if reflection.options[:through]
              "#{reverse_relation[:Comment]}, HOT:#{reflection.name}"
            else
              "#{reverse_relation[:Comment]}, HO:#{reflection.name}"
            end
          else
            result[:Relations] << {
              LeftModelName: model[:ModelName],
              LeftValue: reflection.options[:through] ? "}o" : "||",
              Line: reflection.options[:through] ? ".." : "--",
              RightModelName: reflection_model_name,
              RightValue: "o|",
              Comment: reflection.options[:through] ? "HOT:#{reflection.name}" : "HO:#{reflection.name}"
            }
          end
        end
      end

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
