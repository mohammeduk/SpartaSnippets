# server.rb
require 'sinatra'
require 'mongoid'
require "sinatra/namespace"
require "pry"
# include Mongo

# DB Setup
Mongoid.load! "mongoid.config"
use Rack::MethodOverride

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
      id: @snippet._id.to_s
    }
    data[:errors] = @snippet.errors if@snippet.errors.any?
    data
  end
end

# Endpoints
get '/' do
  $snippets = Snippet.all
  [:question, :answer].each do |filter|
    $snippets = $snippets.send(filter, params[filter]) if params[filter]
  end

  $snippets = $snippets.map { |snippet| SnippetSerializer.new(snippet) }.to_json
  $snippets = JSON.parse($snippets)
  # binding.pry

  erb :index
end

get '/snippets/new' do
  erb :new_snippet
end

get '/snippets/manage' do
  snippets = Snippet.all

  [:question, :answer].each do |filter|
    snippets = snippets.send(filter, params[filter]) if params[filter]
  end

  response = snippets.map { |snippet| SnippetSerializer.new(snippet) }
  json_response = response.to_json
  $snippety = JSON.parse(json_response)
  # binding.pry
  erb :manage_snippets
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

    def snippet
      @snippet ||= Snippet.where(id: params[:id]).first
    end

    def halt_if_not_found!
      halt(404, { message:'Snippet Not Found'}.to_json) unless snippet
    end

    def serialize(snippet)
      SnippetSerializer.new(snippet).to_json
    end

  end

  get '/snippets' do
    snippets = Snippet.all

    [:question, :answer].each do |filter|
      snippets = snippets.send(filter, params[filter]) if params[filter]
    end

    snippets.map { |snippet| SnippetSerializer.new(snippet) }.to_json
  end

  get '/snippets/rand' do
    snippets = Snippet.all

    [:question, :answer].each do |filter|
      snippets = snippets.send(filter, params[filter]) if params[filter]
    end

    rand = Random.new
    rand = rand(0..snippets.count - 1)

    response = snippets.map { |snippet| SnippetSerializer.new(snippet) }[rand]
    response.to_json

  end

  get '/snippets/manage' do
    erb :manage_snippets
  end

  # Edit Snippets confirmation
  get '/snippets/edit' do
    $edit_snippet = params[:snip_q]
    erb :edit_snippet
  end

  get '/snippets/:id' do |id|
    halt_if_not_found!
    serialize(snippet)
  end

  post '/snippets' do
    snippet = Snippet.new(json_params)
    halt 422, serialize(snippet) unless book.snippet
    response.headers['Location'] = "#{base_url}/api/v1/snippets/#{snippet.id}"
    status 201
  end

  post '/snippets/new' do
    # binding.pry
    param_q = params["question"]
    param_a = params["answer"]

    hash = {"question": param_q}, {"answer": param_a}
    hash = hash.to_json
    new_json_snippet = JSON.parse(hash)
    Snippet.create(question:"#{param_q}", answer:"#{param_a}")
    redirect '/snippets/manage'
  end

  patch '/snippets/:id' do |id|
    halt_if_not_found!
    halt 422, serialize(snippet) unless snippet.update_attributes(json_params)
    serialize(snippet)
  end

  post '/snippets/delete/:id' do |id|
    id = params['id'].to_s
    Snippet.where(id: "#{id}").delete
    snippet.destroy if snippet
    status 204
    redirect '/snippets/manage'
  end

  post '/snippets/edit/:id' do |id|
    binding.pry
    id = params['id'].to_s
    Snippet.where(id: "#{id}").delete
    snippet.destroy if snippet
    status 204
    redirect '/snippets/manage'
  end

end
