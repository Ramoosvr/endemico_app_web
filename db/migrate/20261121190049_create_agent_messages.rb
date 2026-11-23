class CreateAgentMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false, default: ""
      t.text :tool_payload

      t.timestamps
    end
    add_index :agent_messages, [ :user_id, :created_at ]
  end
end
