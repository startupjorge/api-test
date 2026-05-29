class CreateCustomQueries < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_queries do |t|
      t.string  :name,        null: false
      t.text    :description
      t.string  :icon,        default: "📊"
      t.string  :query_key,   null: false   # used in URL params
      t.string  :value_path,  null: false   # dot-notation into run response, e.g. "scores.overallScore"
      t.string  :y_axis_label, default: "Score"
      t.boolean :active,      default: true, null: false
      t.timestamps
    end
    add_index :custom_queries, :query_key, unique: true
  end
end
