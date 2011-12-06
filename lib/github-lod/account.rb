require 'digest/sha1'

module GitHubLOD
  ##
  # The Account class reflects the Users API endpoint.
  #
  # Creates a DOAP record for the account, with reference to Person.
  #
  # Note that a GitHub account does _not_ denote user. A user is best modeled as a
  # foaf:Person using a Blank Node, for now.
  #
  # @see http://developer.github.com/v3/users/
  class Account < Base
    attr_reader :subject

    property  RDF::FOAF.OnlineAccount,
                                :predicate => RDF.type, :summary => true
    property   RDF::URI("http://github.com/"),
                                :predicate => RDF::FOAF.accountServiceHomepage
    property   "GitHub",        :predicate => RDF::FOAF.name, :summary => true
    property  :page,            :predicate => RDF::FOAF.page
    property  :homepage,        :predicate => RDF::DOAP.homepage
    property  :login,           :predicate => RDF::FOAF.accountName, :summary => true
    property  :created_at,      :predicate => RDF::DC.created
    reference :person,          :predicate => RDF::FOAF.account, :rev => true, :summary => true

    ##
    # All users, those having a #name
    def self.all
      GitHub::User.all.select(&:name).map {|u| GitHubLOD::Account.new(u)}
    end
    
    ##
    # @param [GitHub::User, String] account
    def initialize(account)
      super(account.is_a?(GitHub::User) ? account : GitHub::User.get(account))
      @subject = RDF::URI.new("http://github.com/#{@api_obj.login}")
    end
    
    ## Accessors ##
    def created_at; RDF::Literal::DateTime.new(api_obj.created_at); end
    def page; subject; end
    def homepage; subject; end
    def person; Person.new(api_obj); end

    ##
    # Also fetch if followers, followings, or repos are empty
    def fetch
      super
      if [:followers, :followings, :repos].any? {|assoc| self.send(assoc).empty?}
        api_obj.fetch(:followers, :followings, :repos)
        @repos = nil
      end
      self
    end

    ##
    # Synchronize object with GitHub
    #
    # @return [Base]
    def sync
      api_obj.fetch(:self, :followers, :followings, :repos)
      @repos = nil
      self
    end

    def repos
      @repos ||= fetch_assoc(:repos, Repository)
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}" + 
      (name.to_s.empty? ? "" : " name: #{name}") +
      " repos: #{repos.length}" +
      ">"
    end

  end
end