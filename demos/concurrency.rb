require 'rubygems'
require 'eventmachine'
require 'em-http-request'

# The number of requests we'll make
num_requests = 20

# An array to track the requests that we've made.
requests     = []

# Headers to send to the echo server.
headers      = { 'X-Mecho-Sleep' => 5 }

# The body of the request
body         = "Well, hello there!"

# Go!
start_time   = Time.now

EM.run do
  num_requests.times do 
    request = EventMachine::HttpRequest.new('http://127.0.0.1:8000/').post(:head => headers, :body => body)
    request.callback do 
      requests.delete(request)
      EM.stop if requests.empty?
    end
    requests << request
  end
end
 
puts "Completed #{num_requests} requests in #{Time.now - start_time}s"

