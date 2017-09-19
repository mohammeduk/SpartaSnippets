# Models
class User
  include Mongoid::Document

  field :username, type: String
  field :password, type: String

  validates :username, presence: true
  validates :password, presence: true

  scope :username, -> (username) { where(username: /^#{username}/) }
  scope :password, -> (password) { where(password: password) }

end
