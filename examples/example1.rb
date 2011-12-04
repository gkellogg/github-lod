#!/usr/bin/env ruby
# Simple graph manipulation
require 'rdf'

include RDF
g = Graph.new
g << Statement.new(
  RDF::URI.new("https://github.com/gkellogg/rdf"),
  RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
  RDF::URI.new("http://usefulinc.com/ns/doap#GitRepository"))

# Using common vocabularies
proj = Node.new
g << Statement.new(proj, RDF.type, DOAP.Project)
g << Statement.new(proj, DOAP.repository,
  RDF::URI.new("https://github.com/gkellogg/rdf"))
puts g.dump(:ntriples)
