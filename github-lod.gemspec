# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "github-lod/version"

Gem::Specification.new do |s|
  s.name        = "github-lod"
  s.date        = File.mtime('lib/github-lod/version.rb').strftime('%Y-%m-%d')
  s.version     = GitHubLOD::VERSION
  s.authors     = ["Gregg Kellogg"]
  s.email       = ["gregg@kellogg-assoc.com"]
  s.homepage    = "http://github.com/gkellogg/github-lod"
  s.summary     = %q{Github API to RDF converter}
  s.description = %q{Provides DOAP, schema.org and FOAF representations of schema.org repositories}

  s.rubyforge_project = "github-lod"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 1.8.7'

  s.add_runtime_dependency      "linkeddata",         '>= 0.3.4'

  # From github-api-client
  s.add_runtime_dependency      'github-api-client',  '>= 0.3.0'
  s.add_runtime_dependency      "rainbow"
  s.add_runtime_dependency      "activerecord",       ">= 3.0.3"
  s.add_runtime_dependency      "activesupport",      ">= 3.0.3"
  s.add_runtime_dependency      "sqlite3-ruby"
  s.add_runtime_dependency      "rdf-xsd",            ">= 0.3.4"
  s.add_runtime_dependency      "activerecord",       "~> 3.0.3"  # Because of github-api-client dependency
  s.add_runtime_dependency      "activesupport",      "~> 3.0.3"  # Because of github-api-client dependency

  # Sinatra dependencies
  s.add_runtime_dependency      "sinatra",            '>= 1.3.1'
  s.add_runtime_dependency      'sinatra-linkeddata', ">= 0.3.0"
  s.add_runtime_dependency      'erubis',             '>= 2.7.0'
  s.add_runtime_dependency      "rack",               '>= 1.3.1'
  s.add_runtime_dependency      'equivalent-xml',     '>= 0.2.8'
  
  s.add_development_dependency  "rspec",              '>= 1.3.5'
end
