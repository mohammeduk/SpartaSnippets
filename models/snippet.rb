# Models
class Snippet
  include Mongoid::Document

  field :question, type: String
  field :answer, type: String

  validates :question, presence: true
  validates :answer, presence: true

  scope :question, -> (question) { where(question: /^#{question}/) }
  scope :answer, -> (answer) { where(answer: answer) }

end
