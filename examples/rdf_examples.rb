#!/usr/bin/env ruby
# Example 1

# Simple Graph Manipulation
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

# Example 2
# Serializing with Writers

require 'rdf/ntriples'
require 'rdf/turtle'

puts NTriples::Writer.buffer {|writer| writer << g};nil

# Also, you can include other formats
puts Turtle::Writer.buffer {|writer| writer << g};nil

# Use Graph.dump or Writer.open to save to a file
puts g.dump(:ttl, :standard_prefixes => true);nil

Turtle::Writer.open('example2.ttl') {|w| w << g};nil
puts File.read('example2.ttl')

# Example 3
# Find Format using symbol or format detection

require 'rdf/rdfa'
require 'rdf/rdfxml'

Writer.for(:ttl)
Writer.for(:content_type => "text/html")
Reader.for('example2.ttl')

# List available formats
RDF::Format.to_a.map(&:to_sym)

# Open a URL and use format detection to find a writer
puts Graph.load('http://greggkellogg.net/foaf').
  dump(:ttl, :base_uri => 'http://greggkellogg.net/foaf',
       :standard_prefixes => true)

f = "http://greggkellogg.net/github-lod/doap.ttl"
Turtle::Reader.open(f) do |reader|
  reader.each {|st| puts st.inspect}
end

# Example 4
# Graph Query

f = "http://greggkellogg.net/github-lod/doap.ttl"
doap = Graph.load(f)

# using RDF::Query
query = Query.new(
  :person => {
      RDF.type  => FOAF.Person,
      FOAF.name => :name,
      FOAF.mbox => :email,
  })
query.execute(doap).each do |soln|
  puts "name: #{soln.name}, email: #{soln[:email]}"
end; nil

# using Query::Pattern
query = Query.new do
  pattern [:project, DOAP.developer, :person]
  pattern [:person, FOAF.name, :name]
end
query.execute(doap).each do |soln|
  puts "project: #{soln.project} name: #{soln.name}"
end; nil

# Example 5
# Graph Navigation

# Traverse via simple queries
puts doap.query(:person, RDF.type, FOAF.Person)

# Example 6
# SPARQL

require 'sparql'

f = "./dumps/github-lod.nt"
doap = Repository.load(f)

query = SPARQL.parse(%q(
  PREFIX doap: <http://usefulinc.com/ns/doap#>
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>

  SELECT ?repo ?name
  FROM NAMED <http://greggkellogg.net/foaf>
  WHERE {
    [ a doap:Project;
      doap:name ?repo;
      doap:developer [ a foaf:Person;
        foaf:name ?name
        ]
    ]
  }
  ORDER BY DESC(?repo)
  LIMIT 20
))
query.execute(doap).each do |soln|
  puts "project: #{soln.repo} name: #{soln.name}"
end; nil

