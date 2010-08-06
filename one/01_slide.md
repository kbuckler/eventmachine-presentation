!SLIDE 
# Event-driven I/O for fun and profit. #

!SLIDE bullets incremental smaller
# What is EventMachine? #
* A single-threaded\*, event driven, asynchronous programming model for Ruby.

!SLIDE bullets incremental smaller
# Single-threaded *and* concurrent? #
* Ruby code runs on a single thread.
* Huh?!

!SLIDE smaller
# Guys, we need to talk about our threads. #

!SLIDE bullets incremental smaller
# The state of Ruby (MRI) concurrency #
* Sure, we have Ruby "green" threads.
* One thread may execute in the interpreter's mutex block at a time.
* Green threads are managed by Ruby in user space, not by the OS.
* These threads must time-share one native OS thread.
* No benefit in multi-core/cpu configurations.

!SLIDE bullets incremental smaller
# The state of Ruby (1.9) concurrency #
* Like MRI - 1.9 has many Ruby "green" threads.
* One thread may execute in the interpreter's mutex block at a time.
* But has a pool of system threads to draw from.
* A better situation then 1.8.7, but not really by that much.

!SLIDE centered smaller 
# Get ready... #

!SLIDE
# _Blocking I/O will block the system thread, and all of your precious green threads with it!_ #

!SLIDE bullets incremental smaller
# More delicately, #
* A blocking I/O call will always block a system thread.
* Green threads divide the execution time of a single shared OS thread.
* All green threads will be blocked by the blocked system thread.
* The interpreter isn't special, it must also wait for the I/O operation to finish.

!SLIDE bullets incremental smaller
# Back to EventMachine #
* An implementation of the "Reactor" pattern, like Twisted and Node.js
* MRI/1.9 implementations are written in C++
* Spend your time writing application code, not network drivers.
* It won't cook breakfast for you in the morning.
* Even if you ask nicely.

!SLIDE
# How does EventMachine acheive concurrency, then? #

!SLIDE bullets incremental smaller
# EventMachine manages your I/O, at a low-level, for you. #
* Turn a blocking IO operation into a non-blocking one.
* Calls return immediately, Ruby-land code is free do work on other things.
* When the I/O call completes, the operating system notifies EventMachine.
* EventMachine _schedules_ execution of any callbacks registered for this operation.

!SLIDE smaller
# HTTP example #

    @@@ ruby
    url = 'http://search.twitter.com/search.json?q=zendesk'
    EM.run do
      EventMachine::HttpRequest.new(url).get do |http|
        http.callback do
          p JSON.parse(http.response)["results"].first
          puts "Done!"
          EventMachine.stop
        end
      end
      puts "Waiting for response..."
    end

!SLIDE bullets incremental smaller
# Libraries. #
* Built-in support for primitive socket and TCP/IP operations.
* Non-blocking drivers available for MySQL, Memcached, MongoDB, Redis, HTTP, DNS, ...
* Roll-your-own IP protocol with EventMachine::Connection.

!SLIDE smaller
# Arbitrary callbacks may be scheduled: #

!SLIDE smaller
# In the future! #

    @@@ruby
    require 'eventmachine'

    EventMachine.run do 
      EM.add_timer(10) do
        # do something ten seconds from now
      end
    end


!SLIDE smaller
# Periodically... #

    @@@ruby
    require 'eventmachine'

    EventMachine.run do 
      EM.add_periodic_timer(10) do
        # do something every ten seconds
      end
    end

!SLIDE smaller
# ASAP! #

    @@@ruby
    require 'eventmachine'

    EventMachine.run do 
      EM.next_tick do
        # do something in the next event cycle
      end
    end

!SLIDE smallest
# Canonical Concurrency Demo #

    @@@ruby
    requests = [] # We'll keep track of active requests here.

    EM.run do
      20.times do 
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8000/')
        request = http.post(:head => headers, :body => body)
        request.callback do 
          requests.delete(request)
          EM.stop if requests.empty? # Stop reactor when all requests complete.
        end
        requests << request
      end
    end

!SLIDE smaller
# Remember that asterisk? We need to talk about threads, again.#

!SLIDE bullets incremental smaller
# EventMachine libraries manage non-blocking I/O for us. #
* We're free to do other things while waiting ...
* ... like responding to other inbound requests. 
* ... like performing CPU bound tasks.
* ... like performing other I/O tasks.

!SLIDE smaller
# But some things are simply not I/O bound. #

!SLIDE bullets incremental smaller
# `EventMachine.defer(your_proc, callback)` #
* Executes `your_proc` on a new thread and returns immediately.
* Draws from a pool of 20 Ruby green threads.
* You could make a bunch of I/O calls on this thread.
* (But we all know you don't really want to!)

!SLIDE smallest
# Multithreaded echo server, using EM.defer #

    @@@ruby 
    class Echo::Server < EM::Protocols::HeaderAndContentProtocol
      def receive_request
        EM.defer(sleep_proc, on_complete)
      end

      # Simulates a long running operation.
      def sleep_proc
        Proc.new do 
          sleep(@duration)
        end
      end

      def on_complete
        Proc.new do 
          send_data(response_headers + @content + "\n")
          write_log_message
          close_connection_after_writing
        end
      end
    end

    EM.run do
      EventMachine::start_server "127.0.0.1", 8000, Echo::Server
    end

!SLIDE bullets incremental smallest
# @Zendesk #
* EventMachine is a big hammer and a lot of things are starting to look like nails.
* The Twickets integration makes thousands of calls to the Twitter API once a minute, every minute, from a single process.
* The proxy is ripe for a rewrite.
* Lightweight services.
* Proxied backends.
 
!SLIDE
# Thanks! #

