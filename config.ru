#!/usr/bin/env rackup
$:.unshift(File.expand_path('../lib',  __FILE__))

ENV['GEM_PATH'] = "/home/kellogg/gems:/usr/lib/ruby/gems/1.8"

require 'rubygems' || Gem.clear_paths
require 'bundler'
Bundler.setup

require 'github-lod'
require 'github-lod/application'

set :environment, (ENV['RACK_ENV'] || 'production').to_sym

if settings.environment == :production
  puts "Mode set to #{settings.environment.inspect}, logging to sinatra.log"
  log = File.new('sinatra.log', 'a')
  STDOUT.reopen(log)
  STDERR.reopen(log)
else
  puts "Mode set to #{settings.environment.inspect}, logging to console"
end

disable :run, :reload

run GitHubLOD::Application
