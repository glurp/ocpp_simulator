#!/usr/bin/ruby
#################################################################################
# wssender.rb : connect to remote websocket serveur, send a text message and wait...
#
# Exemple:
#   > ruby wssender.rb 10.203.76.160 3400 '[2,0,"heartbeat",{}]'
#################################################################################
require 'em-websocket-client'

options = {}
if ARGV.size<2
  puts "Usage : > #{$0} remote-host remote-port  data..." 
  exit(1)
end
url = ARGV.shift
mess = ARGV

EventMachine.run {
  puts "Connecting to #{url}..."
  ws = EventMachine::WebSocketClient.connect(url)
  ws.callback { 
    p "connected"; 
    mess.each_with_index {|m,ii| EM.add_timer(ii+1) {  p "sending #{m} ..." ; ws.send_msg(String.new(m)) } }
  }
  ws.disconnect { p "closed by client" ;  EM::stop_event_loop } 
  ws.stream { |msg| p "received #{msg}" }  
}
