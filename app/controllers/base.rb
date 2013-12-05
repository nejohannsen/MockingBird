module SC
  class BaseController < Sinatra::Base
    require API_ROOT + "/models/location"
    require API_ROOT + "/models/tag"
    require API_ROOT + "/models/link"

    before do
      content_type :json
    end

    def ical data
      content_type :"text/calendar"
      status 200
      halt data.to_ical
    end

    def ok data
      status 200
      halt data.to_json
    end

    def missing
      status 404
      halt
    end
  end
end