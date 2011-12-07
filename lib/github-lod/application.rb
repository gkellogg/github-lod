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
      redirect to("#{BASE_URI}/accounts")
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
        format.nt { Account.singleton }
        format.ttl { Account.singleton }
        format.rdf { Account.singleton }
        format.n3 { Account.singleton }
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
        format.nt     { account }
        format.ttl    { account }
        format.rdf    { account }
        format.n3     { account }
        format.jsonld { account }
      end
    end

    ##
    # Show a users repositories
    get '/accounts/:login/repos/:repo' do
      account = Account.new(params[:login])
      r = account.repos.detect {|r| r.name == params[:repo]}
      r = r.sync
      respond_to do |format|
        format.html do
          erb :repo, :locals => {
            :title => "GitHub repository #{account.login}/#{r.name}",
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
            :repos => Repository.all.sort_by {|r| "#{r.owner.login}/#{r.name}".downcase}
          }
        end

        # Content negotiation
        format.nt     { Repository.singleton }
        format.ttl    { Repository.singleton }
        format.rdf    { Repository.singleton }
        format.n3     { Repository.singleton }
        format.jsonld { Repository.singleton }
      end
    end
  end
end
