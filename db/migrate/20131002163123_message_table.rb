class MessageTable < ActiveRecord::Migration
  def up
  	create_table "messages", :force => true do |t|
	    t.string   "sender_id",                              :null => false
	    t.string   "recepient_id"
	    t.boolean  "sender_deleted",    :default => false
	    t.boolean  "recepient_deleted", :default => false
	    t.string   "subject",                                :null => false
	    t.text     "body"
	    t.datetime "read_at"
	    t.string   "container",         :default => "draft"
	    t.datetime "created_at",                             :null => false
	    t.datetime "updated_at",                             :null => false
	  end
  end

  def down
  	drop_table "messages"
  end
end
