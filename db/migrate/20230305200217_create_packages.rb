class CreatePackages < ActiveRecord::Migration[7.0]
  def change
    create_table :packages do |t|
      t.string :repository
      t.string :name
      t.string :version
      t.string :r_version_needed
      t.string :depends
      t.datetime :publication_date
      t.string :title
      t.string :author
      t.string :maintainer
      t.string :license
      t.jsonb :additional_details

      t.timestamps
    end
  end
end
