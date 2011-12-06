require 'digest/sha1'

module GitHubLOD
  ##
  # Base class for GitHub shims
  class Base
    include RDF::Enumerable
    
    def self.properties; @properties; end
    def self.references; @reference; end

    # Defines property relationships
    #
    # @param [Symbol, Object] accessor
    #   If a symbol, the attribute to reference, otherwise a value for object
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :predicate
    # @option options [Boolean] :rev Reverse the sense of this property
    # @option optinos [Boolean] :summary include in summary information
    def self.property(accessor, options)
      @properties ||= {}
      @properties[accessor] = options
    end

    # Defines a single relationship to another Base sub-class
    #
    # @param [Symbol] accessor
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :predicate
    # @option options [Boolean] :rev Reverse the sense of this property
    # @option optinos [Boolean] :summary include in summary information
    def self.reference(accessor, options)
      @reference ||= {}
      @reference[accessor] = options
    end
    
    attr_reader :api_obj
    attr_reader :subject

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
      api_obj.created_at.today? ? sync : self
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

    ##
    # Generate Statements for user records
    #
    # @param [Boolean] summary Only summary information
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    def each(summary = nil, &block)
      return if subject.nil?
      self.class.properties.each do |accessor, options|
        next if summary && !options[:summary]
        value = accessor.is_a?(Symbol) ? self.send(accessor) : accessor
        next unless value
        yield_attr(value, options, &block)
      end

      # Generate triples for references to other objects
      self.class.references.each do |accessor, options|
        values = [self.send(accessor)].flatten.compact
        values.each do |value|
          next unless value.subject
          # Reference to object
          yield_attr(value.subject, options, &block)

          # Summary information about object
          value.each(:summary, &block)
        end
      end unless summary || self.class.references.nil?
      self
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
    # Create a named node using a safe ID
    def bnode(id)
      RDF::Node(id.gsub(/[^A-Za-z0-9\-_]/, '_'))
    end
    
    ##
    # Yield an attribute using predicate and typing info
    #
    # @param [Symbol] accessor
    # @param [Hash{Symbol => Object}] options
    # @yield statement
    # @yieldparam [RDF::Statement]
    def yield_attr(accessor, options, &block)
      value = accessor.is_a?(Symbol) ? self.send(accessor) : accessor
      return unless value
      if options[:rev]
        yield RDF::Statement.new(value, options[:predicate], subject)
      else
        yield RDF::Statement.new(subject, options[:predicate], value)
      end
    end
  end
end