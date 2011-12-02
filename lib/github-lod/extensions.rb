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
