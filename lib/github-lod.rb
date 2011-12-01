require "github-api-client"
require "github-lod/version"
#require "linkeddata"
require 'rdf/turtle'
require 'rdf/xsd'

module GitHubLOD
  autoload :Repo, 'github-lod/repo'
  autoload :User, 'github-lod/user'
  
  class Schema < ::RDF::Vocabulary("http://schema.org/"); end
end
