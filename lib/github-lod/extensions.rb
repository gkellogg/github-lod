class RDF::Literal
  autoload :Duration, 'rdf/model/literal/duration'
  
  ##
  # Returns a human-readable value for the interval
  def humanize(lang = :en)
    to_s
  end

  class Date
    def humanize(lang = :en)
      @object.strftime("%A, %d %B %Y %Z")
    end
  end
  
  class Time
    def humanize(lang = :en)
      @object.strftime("%r %Z").sub(/\+00:00/, "UTC")
    end
  end
  
  class DateTime
    def humanize(lang = :en)
      @object.strftime("%r %Z on %A, %d %B %Y").sub(/\+00:00/, "UTC")
    end
  end
end

require 'rack/linkeddata'
class Rack::LinkedData::ContentNegotiation
  # Pass more options to the writer
  # Also, be compatible with Sinatra::RespondTo and look at
  # returned Content-Type to find the writer
  def serialize(env, status, headers, body)
    begin
      content_type = headers['Content-Type'].split(';').first
      writer = RDF::Writer.for(:content_type => content_type)
      if writer
        puts "Use writer #{writer} for #{content_type}"
        headers = VARY.merge(headers)
        [status, headers, [writer.dump(body, nil, :standard_prefixes => true)]]
      else
        not_acceptable
      end
    rescue RDF::WriterError => e
      not_acceptable
    end
  end
end

