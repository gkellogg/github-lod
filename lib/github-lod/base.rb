require 'digest/sha1'

module GitHubLOD
  ##
  # Base class for GitHub shims
  class Base
    include RDF::Enumerable

    attr_reader :api_obj
    attr_reader :uri

    def self.inherited(subclass)
      (@@subclasses ||= []) << subclass
    end

    ##
    # All instances
    #
    # Each subclass should implement this method to return all memberes
    #
    # @return [Base]
    def self.all
      @@subclasses.map {|subclass| subclass.all}.flatten
    end
    
    ##
    # All triples
    #
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    def self.each(&block)
      all.each {|r| r.each(&block)}
      self
    end

    ##
    # A singleton class representing the union of all records.
    # Useful for writing RDF, as it implements RDF::Enumerable
    #
    # @return[Base]
    def self.singleton
      @singleton ||= begin
        o = Object.new
        o.extend(RDF::Enumerable)
        def o.each(&block)
          Base.each(&block)
        end
        o
      end
    end

    ##
    # Initialization, should be called as super with api_obj
    #
    # @param [GitHub::Base] api_obj
    def initialize(api_obj)
      @api_obj = api_obj
    end
    
    ##
    # Fetch information about the object, if it is uninitialized
    #
    # @return [Base]
    #   Returns itself
    def fetch
      created_at.today? ? sync : self
    end

    ## Synchronize object with GitHub
    #
    # @return [Base]
    def sync
      api_obj.fetch(:self)
      self
    end

    # Proxy everything else to api_obj
    def method_missing(method, *args)
      api_obj.send(method, *args)
    end

    protected
    ##
    # Fetch the association, recursing to referenced objects
    # and fetching them if the association is empty
    #
    # @param [Symbol] collection to fetch
    # @param [Class] :class (self.class)
    #   Shim class to instantiate members
    def fetch_assoc(method, klass = self.class)
      list = api_obj.send(method, true)
      list.map {|api_obj| klass.new(api_obj)}
    end
    
    ##
    # Yield an attribute using predicate and typing info
    #
    # @param [RDF::Resource] subject
    # @param [Symbol] attr
    # @param [Hash{Symbol => Object}] mapping
    # @yield statement
    # @yieldparam [RDF::Statement]
    def yield_attr(subject, attr, mapping)
      value = self.send(attr)
      klass = mapping[:object_class] || RDF::Literal
      value = klass.new(value) unless value.to_s.empty?
      yield RDF::Statement.new(subject, mapping[:predicate], value) if value
    end
  end
end