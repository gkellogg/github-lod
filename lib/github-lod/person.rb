require 'digest/sha1'

module GitHubLOD
  ##
  # The Person class reflects the Users API endpoint.
  #
  # Creates a FOAF record for the user, with reference to Account.
  #
  # Note that a GitHub account does _not_ denote user. A user is best modeled as a
  # foaf:Person using a Blank Node, for now.
  #
  # @see http://developer.github.com/v3/users/
  class Person < Base
    attr_reader :subject

    property  RDF::FOAF.Person, :predicate => RDF.type,           :summary => true
    property  :name,            :predicate => RDF::FOAF.name,     :summary => true
    property  :login,           :predicate => RDF::FOAF.nick,     :summary => true
    property  :location,        :predicate => RDF::FOAF.based_near
    property  :blog,            :predicate => RDF::FOAF.weblog
    property  :mbox,            :predicate => RDF::FOAF.mbox
    property  :mbox_sha1sum,    :predicate => RDF::FOAF.mbox_sha1sum, :summary => true
    property  :depiction,       :predicate => RDF::FOAF.depiction
    reference :account,         :predicate => RDF::FOAF.account,  :summary => true
    reference :followings,      :predicate => RDF::FOAF.knows
    reference :followers,       :predicate => RDF::FOAF.knows, :rev => true
    reference :projects,        :predicate => RDF::FOAF.developer

    ##
    # All users, those having a #name
    def self.all
      GitHub::User.all.select(&:name).map {|u| GitHubLOD::Person.new(u)}
    end
    
    ##
    # @param [GitHub::User, String] user
    def initialize(user)
      super(user.is_a?(GitHub::User) ? user : GitHub::User.get(user))
      @subject = bnode("user-#{login}")
    end
    
    ## Accessors ##
    def blog; RDF::URI(api_obj.blog) if !api_obj.blog.to_s.empty?; end
    def mbox; RDF::URI("mailto:#{email}") if !email.to_s.empty?; end
    def mbox_sha1sum; Digest::SHA1.hexdigest(mbox) if mbox; end
    def depiction
      RDF::URI("http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}") if !email.to_s.empty?
    end
    def account; Account.new(api_obj); end

    ##
    # Also fetch if followers, followings, or repos are empty
    def fetch
      super
      if [:followers, :followings, :repos].any? {|assoc| self.send(assoc).empty?}
        api_obj.fetch(:followers, :followings, :repos)
        @followers = @followings = @projects = nil
      end
      self
    end

    ##
    # Synchronize object with GitHub
    #
    # @return [Base]
    def sync
      api_obj.fetch(:self, :followers, :followings, :repos)
      @followers = @followings = @projects = nil
      self
    end

    ##
    # Override each to descend into project. Can't do that through normal summary
    # information, as it leads to recursion loops
    #
    # @param [Boolean] summary Only summary information
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    def each(summary = nil, &block)
      super
      projects.each {|p| p.each(&block)} unless summary
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
    
    def projects
      @projects ||= fetch_assoc(:repos, Project)
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}" + 
      (name.to_s.empty? ? "" : " name: #{name}") +
      " followers: #{followers.length}" +
      " followings: #{followings.length}" +
      " projects: #{projects.length}" +
      ">"
    end

  end
end