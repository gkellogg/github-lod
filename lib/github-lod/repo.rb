require 'digest/sha1'

module GitHubLOD
  ##
  # The Repo class reflects the Repo API endpoint.
  #
  # Creates a DOAP record for the repo
  #
  # @see http://developer.github.com/v3/users/
  class Repo
    include RDF::Enumerable

    attr_reader :api_obj
    attr_reader :project_node
    attr_reader :owner
    attr_reader :uri
    attr_reader :wiki_url
    attr_reader :issues_url
    
    PROJECT_FIELD_MAPPINGS = {
      :name => {:predicate => RDF::DOAP.name, :object_class => RDF::Literal},
      :description => {:predicate => RDF::DOAP.description, :object_class => RDF::Literal},
      :language => {:predicate => RDF::DOAP['programming-language'], :object_class => RDF::Literal},
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
      @api_obj = if repo.is_a?(String)
        raise "Creating a repo instance requres a user" unless owner.is_a?(GitHubLOD::User)
        GitHub::Repo.get(:owner => owner, :name => repo)
      else
        repo
      end
      @project_node = RDF::Node("proj-#{api_obj.owner.login}-#{name}")
      @owner = User.new(api_obj.owner)
      @uri = RDF::URI(url)
      @wiki_url = "#{url}/wiki" if has_wiki?
      @issues_url = "#{url}/issues" if has_issues?
    end
    
    ##
    # Generate Statements for user records
    def each
      # Project info
      yield RDF::Statement.new(project_node, RDF.type, RDF::DOAP.Project)

      PROJECT_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield RDF::Statement.new(project_node, mapping[:predicate],
          mapping[:object_class].new(self.send(attr))) unless attr.to_s.empty?
      end

      # Repository info
      yield RDF::Statement.new(uri, RDF.type, RDF::DOAP.GitRepository)

      REPO_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield RDF::Statement.new(uri, mapping[:predicate],
          mapping[:object_class].new(self.send(attr))) unless attr.to_s.empty?
      end

      # Owner info
      yield RDF::Statement.new(project_node, RDF::DOAP.developer, owner.user_node)
      yield RDF::Statement.new(owner.user_node, RDF::type, RDF::FOAF.Person)
      if owner.name
        yield RDF::Statement.new(owner.user_node, RDF::FOAF.name, RDF::Literal(owner.name))
      else
        yield RDF::Statement.new(owner.user_node, RDF::FOAF.nick, RDF::Literal(owner.login))
      end
      yield RDF::Statement.new(owner.user_node, RDF::FOAF.account, RDF::URI(owner.uri))
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id} name: #{name}>"
    end

    # Proxy everything else to api_obj
    def method_missing(method, *args)
      api_obj.send(method, *args)
    end
  end
end