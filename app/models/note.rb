class Note < ActiveRecord::Base
	attr_accessible :item_id, :item_type, :content
	
	belongs_to :item, :polymorphic=>true
	belongs_to :user
	belongs_to :editor
	
	validates_presence_of :item
	validates_presence_of :user
	validates_presence_of :content
end
