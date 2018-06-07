#!/usr/bin/env ruby
require 'em-websocket-client'

###############################################################################################
#      ocpp_router2.rb : create a websocket client, piped via in/out channels
###############################################################################################

require 'json'
require 'time'


class Router
  public
  def initialize(cbi,origine,url)
    @cbi=cbi
    @origine=origine
    url= "#{url}/#{cbi}"
    mlog("starting  redirect to  #{url}")

    make_connection(url,origine)    

  end
  def send_to_routed(msg)
     log "c received->root #{msg}"
     @chInput.push(msg) if @chInput
  end
  def close_route()
    log("s close on c demande...")
    @chInput.push("close please") if @chInput
  end

  private
  def make_connection(url,origine)

    ws = EventMachine::WebSocketClient.connect(url)
  
    #============== Creation Channels piping  origine<->router
    #   origine->receive         -> |chInput|  ->  sub { send_ws_router() }
    #   sub {origine.send_from } <- |chOutput| <-  receive_ws_router
    #
    # message===Array  >> message to send
    # message===String >> destination must close
    
    @chInput = EM::Channel.new
    @chOutput= EM::Channel.new
    
    chOutput_sid=nil
    chOutput_sid = @chOutput.subscribe { |msg| 
      origine.send_from_route(msg) 
    }
    @input_sid = @chInput.subscribe { |msg| 
      if  msg.is_a?(String)
        log "s close on client demand..."
        ws.close_connection()
      else
        log "s send #{msg}"
        ws.send_msg(JSON.generate(msg))
      end
    }

    timer_connection=EM::Timer.new(10) {
        log("timeout connection to s")
        ws.close_connection() rescue nil
    }
    ws.callback {
      timer_connection.cancel
      log "s connected"; 
    }
    ws.disconnect { 
      log "s close" 
      @chInput.unsubscribe(@input_sid) if @input_sid
      @chOutput.push("close")
      EM.add_timer(0) { @chOutput.unsubscribe(chOutput_sid) }
    } 
    ws.stream { |msg| #  receive message from routed
        log "s received #{msg}" 
        begin
          mess=JSON.parse(msg.data)
          @chOutput.push(mess)
        rescue Exception => e
          log("ERROR parsing message from route : #{e}")
        end
    }
  end  
  def log(*t)
    aloc=caller.first.to_s.split(/[: ]in/)
    loc=aloc.first+" "+ aloc.last
    mess="(%s) %-70s (%s)" % [@cbi,t.join(" "),loc] 
    mlog(mess)
  end

end

if $0 == __FILE__
  ##############################################################
  #  Test routing part
  #  Usage: > ruby ocpp_router2.rb ws://google.com:3400
  ##############################################################
  def mlog(*t) puts t end

  class ClientSimulate
    def connect(r)
      @router=r
    end
    def  send_from_route(msg)
       puts "received from server: #{msg.class} #{msg}"
       exit(0) if msg.is_a?(String)
    end
    def test
      i=0
      30.times {  EM.add_timer(i*0.1) {
        @router.send_to_routed([2,i,"meterValues",{}])
        @router.send_to_routed([2,i+1,"Heartbeat",{}])
        @router.send_to_routed([2,i+2,"meterValues",{}])
        i+=10
      } }
    end
  end
  EventMachine.run do
    c=ClientSimulate.new
    r=Router.new("TTTTT",c,ARGV.first || "ws://127.0.0.1:3400") 
    c.connect(r)
    EM.add_timer(1) {c.test }
  end

end

