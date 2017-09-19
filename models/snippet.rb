# Models
class Snippet
  include Mongoid::Document

  field :username, type: String
  field :question, type: String
  field :answer, type: String

  validates :username, presence: true
  validates :question, presence: true
  validates :answer, presence: true

  scope :username, -> (username) { where(username: username) }
  scope :question, -> (question) { where(question: /^#{question}/) }
  scope :answer, -> (answer) { where(answer: answer) }

end
