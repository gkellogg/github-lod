# GitHub Linked Open Data demo
This gem uses the GitHub API to map users and repositories to [DOAP][] and [FOAF][].
It is an example project using [Ruby][] RDF tools to reflect Active Record objects
to [RDF][], either as embedded HTML+RDFa, or using many of other available RDF
serializers included in the application.

The application uses the Okonski [GitHub API Client gem](http://github.com/gkellogg/github-api-client) to access the GitHub JSON API and caches data in a local SQLite3 database using Active Record. This gem acts as a shim on top of those classes to provide [RDF.rb][] interfaces and to create an HTML+RDFa representation. For this we use the [FOAF][] and [DOAP][] RDF vocabularies. It also provides alternative RDF representations of Users and Projects using HTTP content negotiation and/or by appending the appropriate file extension to a request.

## Dependencies
* [ActiveRecord](http://rubygems.org/gems/activerecord")       (~> 3.0.3)
* [ActiveSupport](http://rubygems.org/gems/activesupport")      (~> 3.0.3)
* [Erubis](http://rubygems.org/gems/erubis')             (>= 2.7.0)
* [GitHub](http://rubygems.org/gems/github-api-client')  (>= 0.3.0)
* [JSON::LD](http://rubygems.org/gems/json-ld) (>= 0.0.8)
* [LinkedData](http://rubygems.org/gems/linkeddata) (>= 0.3.4)
* [Rack](http://rubygems.org/gems/rack")               (>= 1.3.1)
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.4)
* [RDF::Isomorphic](http://rubygems.org/gems/rdf-isomorphic) (>= 0.3.4)
* [RDF::JSON](http://rubygems.org/gems/rdf-json) (>= 0.3.0)
* [RDF::Microdata](http://rubygems.org/gems/rdf-microdata) (>= 0.2.2)
* [RDF::N3](http://rubygems.org/gems/rdf-n3) (>= 0.3.6)
* [RDF::RDFa](http://rubygems.org/gems/rdf-rdfa) (>= 0.3.7)
* [RDF::RDFXML](http://rubygems.org/gems/rdf-rdfxml) (>= 0.3.5)
* [RDF::TriX](http://rubygems.org/gems/rdf-trix) (>= 0.3.0)
* [RDF::Turtle](http://rubygems.org/gems/rdf-turtle) (>= 0.1.0)
* [RDF::XSD](http://rubygems.org/gems/rdf-xsd")            (>= 0.3.4)
* [Sinatra::LinkedDaeta](http://rubygems.org/gems/sinatra-linkeddata') (>= 0.3.0)
* [Sinatra::RespondTo](http://rubygems.org/gems/sinatra-respond_to') (>= 0.8.0)
* [Sinatra](http://rubygems.org/gems/sinatra")            (>= 1.3.1)
* [SQLite3](http://rubygems.org/gems/sqlite3-ruby")

## Installation

The recommended installation method is via [Bundler](http://gembundler.com/)

    % gem install bundler
    % bundler install

## Running

This application is designed to be run using [Sinatra](http://www.sinatrarb.com/).
Details of installing will vary depending on hosting provider.

Running locally for development purposes is easiest using [Shutgun](http://rtomayko.github.com/shotgun/).
This can be done by running the following:

    % bundle exec shotgun -p 3000 config.ru

This allows the application to be accessed using http://localhost:3000.

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/gkellogg/github-lod.git

## Authors

* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>
## License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[Ruby]:     http://ruby-lang.org/
[RDF]:      http://www.w3.org/RDF/
[RDF.rb]:   http://rdf.rubyforge.org/
[YARD]:     http://yardoc.org/
[YARD-GS]:  http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[FOAF]:     http://xmlns.com/foaf/spec/ "Friend of a Friend"
[DOAP]:     http://trac.usefulinc.com/doap "Description of a Project"