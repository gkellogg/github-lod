require 'digest/sha1'

module GitHubLOD
  ##
  # The Repo class reflects the Repo API endpoint.
  #
  # Creates a DOAP record for the repo
  #
  # @see http://developer.github.com/v3/users/
  class Repo < Base
    attr_reader :project_node
    attr_reader :owner
    attr_reader :wiki_url
    attr_reader :issues_url
    
    PROJECT_FIELD_MAPPINGS = {
      :name => {:predicate => RDF::DOAP.name},
      :description => {:predicate => RDF::DOAP.description},
      :language => {:predicate => RDF::DOAP['programming-language']},
      :homepage => {:predicate => RDF::DOAP.homepage, :object_class => RDF::URI},
      :uri => {:predicate => RDF::DOAP.repository, :object_class => RDF::URI},
      :wiki_url => {:predicate => RDF::DOAP.wiki, :object_class => RDF::URI},
      :issues_url => {:predicate => RDF::DOAP['bug-database'], :object_class => RDF::URI},
    }

    REPO_FIELD_MAPPINGS = {
      :uri => {:predicate => RDF::DOAP.location, :object_class => RDF::URI},
    }

    ##
    # All repos
    def self.all
      GitHub::Repo.all.map {|r| GitHubLOD::Repo.new(r)}
    end

    ##
    # @param [GitHub::Repo, String] repo
    # @param [GitHubLOD::User] user (nil)
    def initialize(repo, owner = nil)
      api = if repo.is_a?(String)
        raise "Creating a repo instance requres a user" unless owner.is_a?(GitHubLOD::User)
        GitHub::Repo.get(:owner => owner, :name => repo)
      else
        repo
      end
      super(api)
      @project_node = bnode("proj-#{api_obj.owner.login}-#{name}")
      @owner = User.new(api_obj.owner)
    end
    
    # Accessors
    def uri; RDF::URI(url); end
    def wiki_url; "#{url}/wiki" if has_wiki?; end
    def issues_url; "#{url}/issues" if has_issues?; end

    ##
    # Generate Statements for user records
    #
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    def each(&block)
      # Project info
      yield RDF::Statement.new(project_node, RDF.type, RDF::DOAP.Project)

      PROJECT_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield_attr(project_node, attr, mapping, &block)
      end

      # Repository info
      yield RDF::Statement.new(uri, RDF.type, RDF::DOAP.GitRepository)
      REPO_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield_attr(uri, attr, mapping, &block)
      end

      # Owner info
      yield RDF::Statement.new(project_node, RDF::DOAP.developer, owner.user_node)
      yield RDF::Statement.new(owner.user_node, RDF::type, RDF::FOAF.Person)
      {
        :name => {:predicate => RDF::FOAF.name},
        :login => {:predicate => RDF::FOAF.nick},
        :uri => {:predicate => RDF::FOAF.account, :object_class => RDF::URI}
      }.each do |attr, mapping|
        owner.yield_attr(owner.user_node, attr, mapping, &block)
      end
      self
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}" + 
      " owner: #{owner.login}" +
      " name: #{name}" +
      ">"
    end
  end
end