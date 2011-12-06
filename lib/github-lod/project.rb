require 'digest/sha1'

module GitHubLOD
  ##
  # The Project class reflects the Repos API endpoint.
  #
  # Creates a DOAP record for the project, with reference to Owner and Repository.
  #
  # Note that a GitHub repo does _not_ denote project. A project is best modeled as a
  # doap:Project using a Blank Node, for now.
  #
  # @see http://developer.github.com/v3/users/
  class Project < Base
    attr_reader :owner

    property  RDF::DOAP.Project,  :predicate => RDF.type,         :summary => true
    property  :name,              :predicate => RDF::DOAP.name,   :summary => true
    property  :description,       :predicate => RDF::DOAP.description
    property  :language,          :predicate => RDF::DOAP['programming-language']
    property  :homepage,          :predicate => RDF::DOAP.homepage
    property  :wiki,              :predicate => RDF::DOAP.wiki
    property  :issues,            :predicate => RDF::DOAP['bug-database']
    reference :owner,             :predicate => RDF::DC.creator
    reference :repo,              :predicate => RDF::DOAP.repository, :summary => true

    ##
    # Loaded projects, those having a #url
    def self.all
      GitHub::Repo.all.select(&:url).map {|r| GitHubLOD::Project.new(r)}
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
      @subject = bnode("proj-#{api_obj.owner.login}-#{name}")
      @owner = owner || Person.new(api_obj.owner)
    end
    
    ## Accessors #
    def wiki; "#{url}/wiki" if has_wiki?; end
    def issues; "#{url}/issues" if has_issues?; end
    def repo; Repository.new(api_obj); end

    def inspect
      "#<#{self.class.name}:#{self.object_id}" + 
      " owner: #{owner.login}" +
      " name: #{name}" +
      ">"
    end

  end
end