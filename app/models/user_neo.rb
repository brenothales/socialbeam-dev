class UserNeo < Neo4j::Rails::Model
	property :beamer_name, :index => :exact
	property :beamer_id, :index => :exact, :unique => true
	has_n(:friends)

	def self.create_friendship(beamer_1,beamer_2)
		beamer_1.friends<<beamer_2
		beamer_2.friends<<beamer_1
		if beamer_1.save && beamer_2.save
			return true
		else
			false
		end
		#Query Example for Friendship => beamer_1.outgoing(:friends).first
	end
end