# server.rb
require 'sinatra'
require "sinatra/base"
require 'mongoid'
require "sinatra/namespace"
require "pry"
require_relative "./helpers/snippetserializer"
require_relative "./models/snippet"
require_relative "./models/user"
# include Mongo

# DB Setup
Mongoid.load! "mongoid.config"
# use Rack::MethodOverride

class MyApp < Sinatra::Base
  register Sinatra::Namespace
  enable  :sessions, :logging

  configure do
    set :sessions, true
    set :logging, true
    set :public_folder, 'public'
    set :views        , 'views'
    set :root         , File.dirname(__FILE__)
   end

  $counter = 0
  $user = nil

  # Endpoints
  get '/' do
    if session[:id] == nil
      erb :home
    else
      $snippets = Snippet.all
      [:question, :answer].each do |filter|
        $snippets = $snippets.send(filter, params[filter]) if params[filter]
      end
      $snippets = $snippets.map { |snippet| SnippetSerializer.new(snippet) }.to_json
      $snippets = JSON.parse($snippets)
      erb :index
    end
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

  get '/registrations/signup' do
    erb :home
  end

  get '/sessions/login' do
    erb :login
  end

  get '/users/index' do
    binding.pry
    session_id = session[:id]
    $user = User.find(session_id)
    erb :index
  end

  post '/registrations' do
    $user = User.create(username:"#{params['username']}", password:"#{params['password']}")
    $user.save
    session[:id] = $user.id.to_s
    redirect '/users/index'
  end

    namespace '/api/v1' do
      #
      # before do
      #   content_type 'application/json'
      # end

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
        content_type 'application/json'
        snippets = Snippet.all

        [:question, :answer].each do |filter|
          snippets = snippets.send(filter, params[filter]) if params[filter]
        end

        snippets.map { |snippet| SnippetSerializer.new(snippet) }.to_json
      end

      get '/snippets/rand' do
        content_type 'application/json'

        # Random number code for snippets

        # snippets = Snippet.all
        #
        # [:question, :answer].each do |filter|
        #   snippets = snippets.send(filter, params[filter]) if params[filter]
        # end
        #
        # rand = Random.new
        # rand = rand(0..snippets.count - 1)
        #
        # response = snippets.map { |snippet| SnippetSerializer.new(snippet) }[rand]
        # response.to_json

        snippets = Snippet.all

        [:question, :answer].each do |filter|
          snippets = snippets.send(filter, params[filter]) if params[filter]
        end

        $counter += 1
        @count = Snippet.count
        if $counter == @count
          $counter = 0
        elsif $counter > @count
          $counter = 0
        end
        response = snippets.map { |snippet| SnippetSerializer.new(snippet) }[$counter]
        response.to_json

      end

      get '/snippets/manage' do
        content_type 'application/json'
        erb :manage_snippets
      end

      # Edit Snippets confirmation
      get '/snippets/edit' do
        # $edit_snippet = params[:snip_q]
        erb :edit_snippet
      end

      get '/snippets/:id' do |id|
        content_type 'application/json'
        halt_if_not_found!
        serialize(snippet)
      end

      post '/snippets' do
        content_type 'application/json'
        snippet = Snippet.new(json_params)
        halt 422, serialize(snippet) unless book.snippet
        response.headers['Location'] = "#{base_url}/api/v1/snippets/#{snippet.id}"
        status 201
      end

      post '/snippets/new' do
        content_type 'application/json'
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
        content_type 'application/json'
        halt_if_not_found!
        halt 422, serialize(snippet) unless snippet.update_attributes(json_params)
        serialize(snippet)
      end

      post '/snippets/delete/:id' do |id|
        content_type 'application/json'
        id = params['id'].to_s
        Snippet.where(id: "#{id}").delete
        snippet.destroy if snippet
        status 204
        redirect '/snippets/manage'
      end

      # post '/snippets/edit/:id' do |id|
      #   $id = id
      #   $id = params['id'].to_s
      #   a = Snippet.find("#{$id}")
      #   $question = a['question']
      #   $answer = a['answer']
      #   redirect_to '/snippets/edit'
      # # end

      get '/snippets/edit/:id' do |id|
        $id = id
        @id = params['id'].to_s
        a = Snippet.find("#{@id}")
        @question = a['question']
        @answer = a['answer']
        erb :edit_snippet
      end

      post '/snippets/edited/' do
        content_type 'application/json'
        Snippet.where(:id => "#{$id}").update_all(:question => "#{params['question']}", :answer => "#{params['answer']}")
        redirect '/snippets/manage'
      end
    end
end
