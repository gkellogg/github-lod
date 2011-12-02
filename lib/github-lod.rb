require "github-api-client"
require "github-lod/version"
require "linkeddata"
require 'rdf/xsd'
require 'github-lod/extensions'

module GitHubLOD
  autoload :Application, 'github-lod/application'
  autoload :Repo, 'github-lod/repo'
  autoload :User, 'github-lod/user'
  
  class Schema < ::RDF::Vocabulary("http://schema.org/"); end
end
