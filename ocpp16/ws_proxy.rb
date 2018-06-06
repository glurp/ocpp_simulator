#!/usr/bin/env ruby

require 'eventmachine'
require 'em-websocket'
require 'em-websocket-client'
require 'time'

options = {}
if ARGV.size!=3
  puts "Usage : > #{$0} server-port remote-host remote-port"
  exit(1)
end
options[:port] = ARGV[0].to_i
options[:remote_host] = ARGV[1]
options[:remote_port] = ARGV[2].to_i

def glog(*t) 
  aloc=caller.first.to_s.split(/[: ]in/)
  loc=aloc.first+" "+ aloc.last
  mess="%s| %-70s (%s)" % [Time.now.localtime.to_s.split("+",2).first,t.join(" "),loc] 
  puts mess
  File.open("log.txt","a+") {|f| f.puts(mess)}
end

class Link
    def initialize(host,port,path,input, output, server_close_ch, client_close_ch)
      glog "s create"
      @input = input
      @output = output
      @server_close_ch = server_close_ch
      @client_close_ch = client_close_ch
      @input_sid=nil
      
      url="ws://#{host}:#{port}#{path}"
      glog "Connecting to #{url}..."
      ws = EventMachine::WebSocketClient.connect(url)
      ws.callback { 
        glog "connected"; 
        @input_sid = @input.subscribe { |msg| glog "s send #{msg.class} #{msg}" ; ws.send_msg(String.new(msg)) }
      }
      ws.disconnect { 
        glog "s close" ;   
        @input.unsubscribe(@input_sid) if @input_sid
        @client_close_ch.unsubscribe(@client_close_ch_sid) if @client_close_ch_sid
      } 
      ws.stream { |msg| 
          glog "s received #{msg}" 
          @output.push(msg.data)
      }    
      @client_close_ch_sid = @client_close_ch.subscribe { |msg| 
          glog "s close by client"
          ws.close_connection() 
      }
    end
end


EventMachine.run {
  glog("starting on #{options[:port]} redirect to  ws://#{options[:remote_host]}:#{options[:remote_port]}")
  EventMachine::WebSocket.start({:host => "0.0.0.0", :port => options[:port]}) do |ws|
    glog "c open"
    ws.onopen {
      glog "c 2 open"
      chOutput = EM::Channel.new
      chInput = EM::Channel.new
      server_close_ch = EM::Channel.new
      client_close_ch = EM::Channel.new

      chOutput_sid = chOutput.subscribe { |msg| glog "c reply #{msg} #{msg.class}" ;ws.send(msg.to_s) }
      server_close_ch_sid = server_close_ch.subscribe { |msg| glog "c close by s" ; ws.close_connection } 
      
      ws.onmessage { |msg| glog "c received->root #{msg}"; chInput.push(msg)}
      glog "init connect to #{options[:remote_host]}:#{options[:remote_port]} ..."
      Link.new(options[:remote_host],options[:remote_port],"/TEST",
              chInput, chOutput, server_close_ch, client_close_ch)


      ws.onclose {
        chOutput.unsubscribe(chOutput_sid)
        server_close_ch.unsubscribe(server_close_ch_sid)
        client_close_ch.push("exit")
      }
    }
  end
}
