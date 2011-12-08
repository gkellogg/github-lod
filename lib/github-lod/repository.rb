require 'digest/sha1'

module GitHubLOD
  ##
  # The Repository class reflects the Repos API endpoint.
  #
  # Creates a DOAP record for the project, with reference to Owner and Repo.
  #
  # Note that a GitHub repo does _not_ denote project. A project is best modeled as a
  # doap:Project using a Blank Node, for now.
  #
  # @see http://developer.github.com/v3/users/
  class Repository < Base
    attr_reader :owner

    property  RDF::DOAP.GitRepository,  :predicate => RDF.type, :summary => true
    property  :name,              :predicate => RDF::DC.title, :summary => true
    property  :browse,            :predicate => RDF::DOAP.browse, :summary => true
    reference :project,           :predicate => RDF::DOAP.repository, :rev => true, :summary => true

    ##
    # Loaded projects, those having a #url
    def self.all
      GitHub::Repo.all.select(&:url).map {|r| GitHubLOD::Repository.new(r)}
    end
    
    ##
    # @param [GitHub::Repo, String] repo
    # @param [GitHubLOD::User] owner (nil)
    def initialize(repo, owner = nil)
      api = if repo.is_a?(String)
        raise "Creating a repo instance requres a user" unless owner.is_a?(GitHubLOD::User)
        GitHub::Repo.get(:owner => owner, :name => repo)
      else
        repo
      end
      super(api)
      @subject = RDF::URI(url) if url
      @owner = owner || Person.new(api_obj.owner)
    end
    
    ## Accessors #
    def browse; subject; end
    def project; Project.new(api_obj); end

    def inspect
      "#<#{self.class.name}:#{self.object_id}" + 
      " owner: #{owner.login}" +
      " name: #{name}" +
      ">"
    end

  end
end