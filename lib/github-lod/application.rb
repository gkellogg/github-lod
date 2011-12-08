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
    BASE_URI = ENV['RackBaseURI']

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
      redirect to("/accounts")
    end

    ##
    # Show cached accounts
    get '/accounts' do
      respond_to do |format|
        format.html do
          erb :accounts, :locals => {
            :title => "Loaded GitHub accounts",
            # Only accounts with names show up, no login-only accounts
            :accounts => Account.all.sort_by {|u| (u.name || u.login).downcase}
          }
        end

        # Return all loaded users for content negotiation
        format.nt  { RDF::Graph.new << Account.singleton }
        format.ttl { RDF::Graph.new << Account.singleton }
        format.rdf { RDF::Graph.new << Account.singleton }
        format.n3  { RDF::Graph.new << Account.singleton }
      end
    end

    ##
    # Show information for a user, with optional extension
    get '/accounts/:login' do |login|
      account = Account.new(login).sync
      respond_to do |format|
        format.html do
          erb :account, :locals => {
            :title => "GitHub account for #{login}",
            :account => account,
          }
        end
        
        # Content negotiation
        format.nt     { RDF::Graph.new << account }
        format.ttl    { RDF::Graph.new << account }
        format.rdf    { RDF::Graph.new << account }
        format.n3     { RDF::Graph.new << account }
        format.jsonld { RDF::Graph.new << account }
      end
    end

    ##
    # Show a users projects
    get '/accounts/:login/projects/:project' do
      account = Account.new(params[:login])
      r = account.repos.detect {|r| r.name == params[:project]}
      p = r.project.sync
      respond_to do |format|
        format.html do
          erb :project, :locals => {
            :title => "GitHub repository #{account.login}/#{p.name}",
            :project => p,
          }
        end

        # Content negotiation
        format.nt     { RDF::Graph.new << p }
        format.ttl    { RDF::Graph.new << p }
        format.rdf    { RDF::Graph.new << p }
        format.n3     { RDF::Graph.new << p }
        format.jsonld { RDF::Graph.new << p }
      end
    end

    ##
    # Show cached projects
    get '/projects' do
      respond_to do |format|
        format.html do
          erb :projects, :locals => {
            :title => "Loaded GitHub projects",
            :projects => Project.all.sort_by {|o| "#{p.owner.login}/#{p.name}".downcase}
          }
        end

        # Content negotiation
        format.nt     { RDF::Graph.new << Project.singleton }
        format.ttl    { RDF::Graph.new << Project.singleton }
        format.rdf    { RDF::Graph.new << Project.singleton }
        format.n3     { RDF::Graph.new << Project.singleton }
        format.jsonld { RDF::Graph.new << Project.singleton }
      end
    end
  end
end
