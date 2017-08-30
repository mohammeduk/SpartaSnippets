# server.rb
require 'sinatra'
require 'mongoid'
require "sinatra/namespace"
require "pry"

# DB Setup
Mongoid.load! "mongoid.config"

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

# Serializers
class SnippetSerializer
  def initialize(snippet)
    @snippet = snippet
  end

  def as_json(*)
    data = {
      question:@snippet.question,
      answer:@snippet.answer,
    }
    data[:errors] = @snippet.errors if@snippet.errors.any?
    data
  end
end

# Endpoints
get '/' do
  'Welcome to SpartaSnippets!'
end

namespace '/api/v1' do

  before do
    content_type 'application/json'
  end

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message:'Invalid JSON' }.to_json
      end
    end
  end

  get '/snippets' do
    snippets = Snippet.all

    [:question, :answer].each do |filter|
      snippets = snippets.send(filter, params[filter]) if params[filter]
    end

    snippets.map { |snippet| SnippetSerializer.new(snippet) }.to_json
  end

  get '/snippets/:id' do |id|
    snippet = Snippet.where(id: id).first
    halt(404, { message:'Snippet Not Found'}.to_json) unless snippet
    SnippetSerializer.new(snippet).to_json
  end

  post '/snippets' do
    snippet = Snippet.new(json_params)
    if snippet.save
      # binding.pry
      response.headers['Location'] = "#{base_url}/api/v1/snippets/#{snippet.id}"
      status 201
    else
      status 422
      body SnippetSerializer.new(snippet).to_json
    end
  end

end
