require 'sinatra'
require 'sinatra/linkeddata'   # Can't use this, as we may need to set by hand, and have to pass options to the serializer
require 'sinatra/partials'
require 'erubis'

module GitHubLOD
  class Application < Sinatra::Base
    helpers Sinatra::Partials
    set :views, ::File.expand_path('../views',  __FILE__)

    before do
      puts "[#{request.path_info}], #{params.inspect}"
    end

    get '/' do
      redirect to('/users')
    end

    ##
    # Show cached users
    get '/users' do
      erb :users, :locals => {
        :title => "Loaded GitHub users",
        :users => User.all.sort_by {|u| u.name || u.login}
      }
    end

    ##
    # Show information for a user
    get '/users/:login' do
      erb :user, :locals => {
        :title => "GitHub account for #{params[:login]}",
        :user => User.new(params[:login]).fetch,
      }
    end

    ##
    # Show a users repositories
    get '/users/:login/repos' do
      erb :user, :locals => {
        :title => "GitHub repositories for #{params[:login]}",
        :repos => User.new(params[:login]).repos,
      }
    end

    ##
    # Show a users repositories
    get '/users/:login/repo/:repo' do
      u = User.new(params[:login])
      r = u.repos.detect {|r| r.name == params[:repo]}.fetch
      erb :repo, :locals => {
        :title => "GitHub repository #{u.login}/#{r.name}",
        :repo => r,
      }
    end

    ##
    # Show cached repos
    get '/repos' do
      erb :repos, :locals => {
        :title => "Loaded GitHub repositories",
        :repos => Repo.all.sort_by {|r| "#{r.owner.login}/#{r.name}"}
      }
    end

    private

    # Return ordered accept mime-types
    def accepts
      types = []
      request.env["HTTP_ACCEPT"].to_s.split(",").each do |type|
        t, q = type.split(';q=')
        q ||= t =~ /xml$/ ? "0.9" : "1"   # WebKit places application/xml at same priority as /html
        types << [t, q.to_i]
      end

      types.sort {|a, b| b[1] <=> a[1]}.map {|(t, q)| t}
    end

    # Parse HTTP Accept header and find an suitable RDF writer
    def writer(format = nil)
      if format && format.to_sym != :accept
        fmt = RDF::Format.for(format.to_sym)
        return [format.to_sym, fmt.content_type.first] if fmt
      end
      
      # Look for formats matching accept headers
      accepts.each do |t|
        writer = RDF::Writer.for(:content_type => t)
        return [writer.to_sym, t] if writer
      end

      return [:ntriples, "text/plain"]
    end
    
    # Format symbol for RDF formats
    # @param [Symbol] reader_or_writer
    # @return [Array<Symbol>] List of format symbols
    def formats(reader_or_writer = nil)
      # Symbols for different input formats
      RDF::Format.select do |f|
        reader_or_writer != :reader || f.reader
        reader_or_writer != :writer || f.writer
      end.map(&:to_sym).sort_by(&:to_s)
    end

  end
end
