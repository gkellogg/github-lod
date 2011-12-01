require "github-api-client"
require "github-lod/version"
#require "linkeddata"
require 'rdf/turtle'
require 'rdf/xsd'

module GitHubLOD
  autoload :User, 'github-lod/user'
  # Your code goes here...
  
  class Schema < ::RDF::Vocabulary("http://schema.org/"); end
end
