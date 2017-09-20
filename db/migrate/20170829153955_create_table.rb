class CreateTable < ActiveRecord::Migration[5.1]
  def change
    create_table :snippetqa do |t|
      t.string :question
      t.string :answer
    end
  end
end
