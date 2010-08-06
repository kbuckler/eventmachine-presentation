require 'rubygems'
require 'eventmachine'
require 'em-http-request'
require 'json'

EM.run do
  EventMachine::HttpRequest.new('http://search.twitter.com/search.json?q=zendesk').get do |http|
    http.callback do
      p JSON.parse(http.response)["results"].first
      EventMachine.stop
    end
  end
  puts "Waiting..."
end
