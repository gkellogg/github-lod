require 'sinatra'
require 'sinatra/linkeddata'
require 'sinatra/partials'
require 'sinatra/respond_to'
require 'erubis'

module GitHubLOD
  class Application < Sinatra::Base
    register Sinatra::RespondTo
    register Sinatra::LinkedData
    helpers Sinatra::Partials
    set :views, ::File.expand_path('../views',  __FILE__)

    # Register some basic RDF mime types.
    # This could be done automatically by iterating
    # through available formats
    mime_type "nt", "text/plain"
    mime_type "ttl", "text/turtle"
    mime_type "n3", "text/rdf+n3"
    mime_type "jsonld", "application/ld+json"

    before do
      puts "[#{request.path_info}], #{params.inspect}, #{format}, #{request.accept}"
      
      # Set the content type from Accept to get RespondTo to work properly
      fmt = Rack::Mime::MIME_TYPES.invert[request.accept.first]
      if !request.accept.include?("text/html") && fmt
        puts " set format to #{fmt[1..-1]}"
        content_type fmt[1..-1]
      end
    end

    get '/' do
      redirect to('/users')
    end

    ##
    # Show cached users
    get '/users' do
      respond_to do |format|
        format.html do
          erb :users, :locals => {
            :title => "Loaded GitHub users",
            # Only users with names show up, no login-only accounts
            :users => User.all.select(&:name).sort_by {|u| (u.name || u.login).downcase}
          }
        end

        # Return all loaded users for content negotiation
        format.nt { User.singleton }
        format.ttl { User.singleton }
        format.rdf { User.singleton }
        format.n3 { User.singleton }
      end
    end

    ##
    # Show information for a user, with optional extension
    get '/users/:login' do |login|
      puts "user: #{login.inspect}, format: #{format}, Accept: #{env['HTTP_ACCEPT']}"
      user = User.new(login).fetch
      respond_to do |format|
        format.html do
          erb :user, :locals => {
            :title => "GitHub account for #{login}",
            :user => user,
          }
        end
        
        # Content negotiation
        format.nt     { user }
        format.ttl    { user }
        format.rdf    { user }
        format.n3     { user }
        format.jsonld { user }
      end
    end

    ##
    # Show a users repositories
    get '/users/:login/repos/:repo' do
      u = User.new(params[:login])
      r = u.repos.detect {|r| r.name == params[:repo]}.fetch
      respond_to do |format|
        format.html do
          erb :repo, :locals => {
            :title => "GitHub repository #{u.login}/#{r.name}",
            :repo => r,
          }
        end

        # Content negotiation
        format.nt     { r }
        format.ttl    { r }
        format.rdf    { r }
        format.n3     { r }
        format.jsonld { r }
      end
    end

    ##
    # Show cached repos
    get '/repos' do
      respond_to do |format|
        format.html do
          erb :repos, :locals => {
            :title => "Loaded GitHub repositories",
            :repos => Repo.all.sort_by {|r| "#{r.owner.login}/#{r.name}".downcase}
          }
        end

        # Content negotiation
        format.nt     { Repo.singleton }
        format.ttl    { Repo.singleton }
        format.rdf    { Repo.singleton }
        format.n3     { Repo.singleton }
        format.jsonld { Repo.singleton }
      end
    end
  end
end
