require "yaml"

class RailsMermaidErd::Builder
  class << self
    def model_data
      result = {
        Models: [],
        Relations: []
      }

      ::Rails.application.eager_load!
      ::ActiveRecord::Base.descendants.each do |defined_model|
        next unless defined_model.table_exists?
        next if defined_model.name.include?("HABTM_")
        next if defined_model.table_name.blank?

        model = {
          TableName: defined_model.table_name,
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

        defined_model.reflect_on_all_associations(:has_many).each do |reflection|
          reflection_model_name = get_reflection_model_name(reflection)

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

        defined_model.reflect_on_all_associations(:has_and_belongs_to_many).each do |reflection|
          reflection_model_name = get_reflection_model_name(reflection)

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

        defined_model.reflect_on_all_associations(:belongs_to).each do |reflection|
          reflection_model_name = get_reflection_model_name(reflection)

          reverse_relation = result[:Relations].find { |r| r[:RightModelName] == model[:ModelName] && r[:LeftModelName] == reflection_model_name }
          if reverse_relation
            if (::Rails.application.config.active_record.belongs_to_required_by_default && reflection.options[:optional]) || (!::Rails.application.config.active_record.belongs_to_required_by_default && !reflection.options[:requried])
              reverse_relation[:LeftValue] = "|o"
            end
            reverse_relation[:Comment] = "#{reverse_relation[:Comment]}, BT:#{reflection.name}"
          else
            right_value = if (::Rails.application.config.active_record.belongs_to_required_by_default && reflection.options[:optional]) || (!::Rails.application.config.active_record.belongs_to_required_by_default && !reflection.options[:requried])
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

        defined_model.reflect_on_all_associations(:has_one).each do |reflection|
          reflection_model_name = get_reflection_model_name(reflection)

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

    # Doc: https://guides.rubyonrails.org/association_basics.html
    def get_reflection_model_name(reflection)
      if reflection.options[:class_name]
        reflection.options[:class_name].to_s.classify
      elsif reflection.options[:through]
        if reflection.options[:source]
          reflection.options[:source].to_s.classify
        else
          reflection.class_name
        end
      else
        reflection.class_name
      end
    end
  end
end
