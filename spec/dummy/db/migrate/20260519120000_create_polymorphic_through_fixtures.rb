class CreatePolymorphicThroughFixtures < ActiveRecord::Migration[7.1]
  def change
    create_table :care_types do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :coordinator_matching_infos do |t|
      t.string :first_name

      t.timestamps
    end

    create_table :caregiver_matching_infos do |t|
      t.string :first_name

      t.timestamps
    end

    create_table :matching_info_care_types do |t|
      t.references :care_type, null: false, foreign_key: true
      t.references :matching_info, polymorphic: true, null: false

      t.timestamps
    end
  end
end
