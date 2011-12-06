require "github-api-client"
require "github-lod/version"
require "linkeddata"
require 'rdf/xsd'
require 'github-lod/extensions'
require 'github-lod/base'
#require 'github-lod/repo'
#require 'github-lod/user'
require 'github-lod/account'
require 'github-lod/person'
require 'github-lod/project'
require 'github-lod/repository'

module GitHubLOD
  autoload :Application, 'github-lod/application'
  
  class Schema < ::RDF::Vocabulary("http://schema.org/"); end
end
