require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    has_many :recruits
    has_many :chats
    has_many :joins
    has_many :join_talkrooms, :through => :joins, :source => :talkroom
    has_many :reviewer, class_name: "Review", foreign_key: "reviewer_id"
    has_many :reviewed, class_name: "Review", foreign_key: "reviewed_id"
    has_many :reviewer_users, :through => :reviewer, :source => :reviewed #自分が評価した人
    has_many :reviewed_users, :through => :reviewed, :source => :reviewer #自分を評価した人
end

class Recruit < ActiveRecord::Base
    belongs_to :user
    belongs_to :category
    belongs_to :model
    belongs_to :game
end

class Game < ActiveRecord::Base
    has_many :recruits
    belongs_to :model
    belongs_to :category
end

class Model < ActiveRecord::Base
    has_many :games
    has_many :recruits
end

class Category < ActiveRecord::Base
    has_many :games
    has_many :recruits
end

class Talkroom < ActiveRecord::Base
    belongs_to :recruit
    has_many :chats
    has_many :joins
    has_many :join_users, :through => :joins, :source => :use
end

class Chat < ActiveRecord::Base
    belongs_to :talkroom
    belongs_to :user
end

class Join < ActiveRecord::Base
    belongs_to :user
    belongs_to :talkroom
end

class Review < ActiveRecord::Base
    belongs_to :reviewer, class_name: "User"
    belongs_to :reviewed, class_name: "User"
end