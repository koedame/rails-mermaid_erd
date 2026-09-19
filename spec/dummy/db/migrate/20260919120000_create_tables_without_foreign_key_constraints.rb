class CreateTablesWithoutForeignKeyConstraints < ActiveRecord::Migration[5.2]
  def change
    # Columns that link to another table by convention only: no database
    # constraint backs them.
    create_table :bookmarks do |t|
      t.bigint :post_id, null: false
      t.bigint :reader_id, null: false

      t.timestamps
    end

    create_table :notes do |t|
      t.bigint :post_id, null: false
      t.string :body, null: false

      t.timestamps
    end

    create_table :memberships, primary_key: [:organization_code, :member_code] do |t|
      t.string :organization_code, null: false
      t.string :member_code, null: false
      t.string :role
    end
  end
end
