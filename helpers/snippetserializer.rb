# Serializers
class SnippetSerializer
  def initialize(snippet)
    @snippet = snippet
  end

  def as_json(*)
    data = {
      question:@snippet.question,
      answer:@snippet.answer,
      id: @snippet._id.to_s
    }
    data[:errors] = @snippet.errors if@snippet.errors.any?
    data
  end
end
