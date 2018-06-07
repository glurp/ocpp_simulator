#!/usr/bin/ruby
#################################################################################
# wssender.rb : connect to remote websocket serveur, send a text message and wait...
#
# Exemple:
#   > ruby ws_sender.rb ws://10.203.76.160:3400/ddd '[2,0,"heartbeat",{}]'
#   > ruby ws_sender.rb --stop ws://10.203.76.160:3400/ddd '[2,0,"heartbeat",{}]' '[2,0,"heartbeat",{}]' '[2,0,"heartbeat",{}]' '[2,0,"heartbeat",{}]'
#################################################################################
require 'em-websocket-client'

options = {}
autostop=false
if ARGV.first=="--stop"
 autostop=true
 ARGV.shift
end
if ARGV.size<2
  puts "Usage : > #{$0} [--stop] remote-host remote-port  data..." 
  exit(1)
end
url = ARGV.shift
mess = ARGV

EventMachine.run {
  puts "Connecting to #{url}..."
  ws = EventMachine::WebSocketClient.connect(url)
  ws.callback { 
    mess.each_with_index {|m,ii|  p "sending #{m} ..." ; ws.send_msg(String.new(m)) }
  }
  ws.disconnect { p "closed by client" ;  EM::stop_event_loop } 
  ws.stream { |msg| p "received #{msg}" }  
  ( EM.add_timer(3+1 * mess.size) { exit(0) } ) if autostop
}
