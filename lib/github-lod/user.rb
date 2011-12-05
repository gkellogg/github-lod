require 'digest/sha1'

module GitHubLOD
  ##
  # The User class reflects the Users API endpoint.
  #
  # Creates a FOAF record for the user and account, with DOAP references to repositories.
  #
  # Note that a GitHub account does _not_ denote user. A user is best modeled as a
  # foaf:Person using a Blank Node, for now.
  #
  # The GitHub account is a foaf:OnlineAccout, referenced by the user
  #
  # @see http://developer.github.com/v3/users/
  class User < Base
    attr_reader :user_node
    
    USER_FIELD_MAPPINGS = {
      :name => {:predicate => RDF::FOAF.name, :object_class => RDF::Literal},
      :location => {:predicate => RDF::FOAF.based_near, :object_class => RDF::Literal},
      :blog => {:predicate => RDF::FOAF.weblog, :object_class => RDF::URI},
      :mbox => {:predicate => RDF::FOAF.mbox, :object_class => RDF::URI},
      :mbox_sha1sum => {:predicate => RDF::FOAF.mbox_sha1sum, :object_class => RDF::Literal::HexBinary},
      :uri => {:predicate => RDF::FOAF.account, :object_class => RDF::URI},
      :depiction => {:predicate => RDF::FOAF.depiction, :object_class => RDF::URI},
    }

    ACCOUNT_FIELD_MAPPINGS = {
      :login => {:predicate => RDF::FOAF.accountName, :object_class => RDF::Literal},
      :created_at => {:predicate => RDF::DC.created, :object_class => RDF::Literal::DateTime},
    }

    ##
    # All users, those having a #name
    def self.all
      GitHub::User.all.select(&:name).map {|u| GitHubLOD::User.new(u)}
    end
    
    ##
    # @param [GitHub::User, String] user
    def initialize(user)
      super(user.is_a?(GitHub::User) ? user : GitHub::User.get(user))
      @uri = RDF::URI.new("http://github.com/#{@api_obj.login}")
      @user_node = bnode("user-#{login}")
    end
    
    ## Accessors ##
    def mbox; "mailto:#{email}" if !email.to_s.empty?; end
    def mbox_sha1sum; Digest::SHA1.hexdigest(mbox) if mbox; end
    def depiction
      "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}" if !email.to_s.empty?
    end

    ##
    # Also fetch if followers, followings, or repos are empty
    def fetch
      super
      if [:followers, :followings, :repos].any? {|assoc| self.send(assoc).empty?}
        api_obj.fetch(:followers, :followings, :repos)
        @followers = @followings = @repos = nil
      end
      self
    end

    ##
    # Synchronize object with GitHub
    #
    # @return [Base]
    def sync
      api_obj.fetch(:self, :followers, :followings, :repos)
      @followers = @followings = @repos = nil
      self
    end

    ##
    # Generate Statements for user records
    #
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    def each(&block)
      # Github Account info
      yield RDF::Statement.new(uri, RDF.type, RDF::FOAF.OnlineAccout)
      yield RDF::Statement.new(uri, RDF::FOAF.accountServiceHomepage, RDF::URI("http://github.com/"))
      yield RDF::Statement.new(uri, RDF::FOAF.name, RDF::Literal("GitHub"))
      yield RDF::Statement.new(uri, RDF::FOAF.page, uri)
      yield RDF::Statement.new(uri, RDF::DOAP.homepage, uri)

      ACCOUNT_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield_attr(uri, attr, mapping, &block)
      end

      # User type
      [RDF::FOAF.Person, Schema.Person].each do |type|
        yield RDF::Statement.new(user_node, RDF.type, type)
      end

      # User info, with unknown FOAF identifier
      USER_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield_attr(user_node, attr, mapping, &block)
      end

      # Followers
      # Don't cause it to fault in, if not already loaded
      followers.each do |f|
        yield RDF::Statement.new(f.user_node, RDF::FOAF.knows, user_node)
        if f.name
          yield RDF::Statement.new(f.user_node, RDF::FOAF.name, RDF::Literal(f.name))
        else
          yield RDF::Statement.new(f.user_node, RDF::FOAF.nick, RDF::Literal(f.login))
        end
        yield RDF::Statement.new(f.user_node, RDF::FOAF.account, RDF::URI(f.uri))
      end unless followers.empty? 

      # Follows
      # Don't cause it to fault in, if not already loaded
      followings.each do |f|
        yield RDF::Statement.new(user_node, RDF::FOAF.knows, f.user_node)
        if f.name
          yield RDF::Statement.new(f.user_node, RDF::FOAF.name, RDF::Literal(f.name))
        else
          yield RDF::Statement.new(f.user_node, RDF::FOAF.nick, RDF::Literal(f.login))
        end
        yield RDF::Statement.new(f.user_node, RDF::FOAF.account, RDF::URI(f.uri))
      end unless followings.empty?
      
      # Repositories
      # Don't cause it to fault in, if not already loaded
      repos.each do |r|
        yield RDF::Statement.new(user_node, RDF::FOAF.developer, r.project_node)
        yield RDF::Statement.new(r.project_node, RDF.type, RDF::DOAP.Project)
        yield RDF::Statement.new(r.project_node, RDF::DOAP.name, r.name)
      end unless repos.empty?
      self
    end

    ##
    # Get follower objects
    #
    # @return [User]
    def followers
      @followers ||= fetch_assoc(:followers)
    end
    
    ##
    # Get followings objects
    #
    # @return [User]
    def followings
      @followings ||= fetch_assoc(:followings)
    end
    
    def repos
      @repos ||= fetch_assoc(:repos, Repo)
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}" + 
      (name.to_s.empty? ? "" : " name: #{name}") +
      " login: #{login}" +
      " followers: #{followers.length}" +
      " followings: #{followings.length}" +
      " repos: #{repos.length}" +
      ">"
    end

  end
end