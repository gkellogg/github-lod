require 'digest/sha1'

module GitHubLOD
  ##
  # The User class reflects the Users API endpoint.
  #
  # Creates a FOAF record for the user and account, with DOAP references to repositories.
  #
  # @see http://developer.github.com/v3/users/
  class User
    include RDF::Enumerable

    attr_reader :api_obj
    attr_reader :uri
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
    # @param [GitHub::User, String] user
    def initialize(user)
      @api_obj = user.is_a?(GitHub::User) ? user : GitHub::User.get(user)
      @uri = RDF::URI.new("http://github.com/#{@api_obj.login}")
      @user_node = RDF::Node.new("user-#{login}")
    end
    
    ## Accessors ##
    def mbox; "mailto:#{email}"; end
    def mbox_sha1sum; Digest::SHA1.hexdigest(mbox) if mbox; end
    def depiction
      "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}" if email && gravatar_id
    end

    ##
    # Generate Statements for user records
    def each
      # Github Account info
      yield RDF::Statement.new(uri, RDF.type, RDF::FOAF.OnlineAccout)
      yield RDF::Statement.new(uri, RDF::FOAF.accountServiceHomepage, RDF::URI("http://github.com/"))
      yield RDF::Statement.new(uri, RDF::FOAF.name, RDF::Literal("GitHub"))

      ACCOUNT_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield RDF::Statement.new(uri,
          mapping[:predicate],
          mapping[:object_class].new(self.send(attr))) unless attr.to_s.empty?
      end

      # User type
      [RDF::FOAF.Person, Schema.Person].each do |type|
        yield RDF::Statement.new(user_node, RDF.type, type)
      end

      # User info, with unknown FOAF identifier
      USER_FIELD_MAPPINGS.each_pair do |attr, mapping|
        yield RDF::Statement.new(user_node,
          mapping[:predicate],
          mapping[:object_class].new(self.send(attr))) unless attr.to_s.empty?
      end

      # Followers
      followers.each do |f|
        yield RDF::Statement.new(f.user_node, RDF::FOAF.knows, user_node)
        if f.name
          yield RDF::Statement.new(f.user_node, RDF::FOAF.name, RDF::Literal(f.name))
        else
          yield RDF::Statement.new(f.user_node, RDF::FOAF.nick, RDF::Literal(f.login))
        end
        yield RDF::Statement.new(f.user_node, RDF::FOAF.account, RDF::URI(f.uri))
      end

      # Follows
      followings.each do |f|
        yield RDF::Statement.new(user_node, RDF::FOAF.knows, f.user_node)
        if f.name
          yield RDF::Statement.new(f.user_node, RDF::FOAF.name, RDF::Literal(f.name))
        else
          yield RDF::Statement.new(f.user_node, RDF::FOAF.nick, RDF::Literal(f.login))
        end
        yield RDF::Statement.new(f.user_node, RDF::FOAF.account, RDF::URI(f.uri))
      end
      
      # Repositories
      repos.each do |r|
        yield RDF::Statement.new(user_node, RDF::FOAF.developer, r.project_node)
        yield RDF::Statement.new(r.project_node, RDF::DOAP.name, r.name)
      end
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
      (name ? " name: #{name}" : " login: #{login}") +
      ">"
    end

    # Proxy everything else to api_obj
    def method_missing(method, *args)
      api_obj.send(method, *args)
    end

    protected
    ##
    # Fetch the association, recursing to referenced objects
    # and fetching them if the association is empty
    def fetch_assoc(method, klass = self.class)
      list = api_obj.send(method)
      if list.empty?
        # Fitch missing associationg
        api_obj.fetch(method)
        list = api_obj.send(method)
      end
      list.each do |r|
         # Fetch unfetched records
        r.fetch(:self) if r.created_at.today?
      end
      list.map {|api_obj| klass.new(api_obj)}
    end
  end
end