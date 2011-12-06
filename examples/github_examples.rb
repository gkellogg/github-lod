#!/usr/bin/env ruby

# Simple Graph Manipulation
require 'bundler'
require 'rdf/turtle'
Bundler.setup

# Example 6
# RDF Graph behavior

require 'github-api-client'
class GitHub::User
  include RDF::Enumerable
  def each
    u = RDF::URI("http://github.com/#{login}")
    yield RDF::Statement.new(u, RDF::FOAF.name, name)
    yield RDF::Statement.new(u, RDF::mbox, RDF::URI("mailto:#{email}")) unless email.nil?
  end
end

u = GitHub::User.get('gkellogg')
puts u.dump(:ttl, :standard_prefixes => true)
