#!/usr/bin/ruby

require 'femtows'
require 'eventmachine'
require 'em-websocket'
require 'Ruiby'
require 'json'

# gem install eventmachine em-websocket 
# gem install femtows Ruiby             # for debug

#############################################################
#   ws_server.rb : serveur webSocket : 
#   Usage :
#     > scada.rb port 
#        port   ==> webseocketserver port
#        port+1 ==> Http server port
#############################################################
#  message= [type,id,Action,data]
#  type:
#  ====
#     CALL       : [<MessageTypeId> (2), "<UniqueId>", "<Action>", {<Payload>}]
#     CALLRESULT : [<MessageTypeId> (3), "<UniqueId>", {<Payload>}]
#     CALLERROR  : [<MessageTypeId> (4) , "<UniqueId>", "<errorCode>", "<errorDescription>", {<errorDetails>}]
#                                                        ^NotSupported InternalError ProtocolError SecurityError 
#                                                         FormationViolation PropertyConstraintViolation  
#                                                         OccurenceConstraintViolation TypeConstraintViolation GenericError 
#  CP=>CS : CALL => CALLRESULT | CALLERROR  
#  CS=>CP : idem (!)
#     CALL       = 2
#     CALLRESULT = 3
#     CALLERROR= = 4
#
#  id:
#  ===
#    nombre, en string different pour chaque  CALL , meme nombre pour le CALLRESULT ( ou CALLERROR)
#  Action
#  ======
#     nom de la requete: "BootNotification"
#  data
#  =======
#    objet JSON
#
# Exemples 
=begin
[2,
 "19223201",
 "BootNotification",
 {"chargePointVendor": "VendorX", "chargePointModel": "SingleSocketCharger"}
]
[3,
 "19223201",
 {"status":"Accepted", "currentTime":"2013-02-01T20:53:32.486Z", "heartbeatInterval":300}
]
=end
#############################################################

module EvSiReceiver
  #------------------ Requests
  
  def do_bootnotification(mess) {status: "Accepted", currentTime: get_time(), interval: 600 }  end
  def do_datatransfer(mess)     {status: "Accepted"}      end
  def do_diagnosticsstatusnotification(mess)  {}          end
  def do_firmwarestatusnotification(mess)  {}             end
  def do_heartbeat(mess)        {currentTime: get_time()} end
  def do_authorize(mess)         mess["idTag"] ? {status: "Accepted"} : raise("tagId manquant en requette Authorize")
  end
  
  def do_metervalues(mess)        {}                      end
  def do_statusnotification(mess) {}                     end
  def do_starttransaction(mess)   {idTagInfo: {expiryDate: get_time(1000),parentIdTag: "",status: "Accepted"},transactionId: 333333}  end
  def do_stoptransaction(mess)     {idTagInfo: {status: "Accepted"}} end

  
  #?
  def do_triggermessage(mess)  end
  def do_getcompositeschedule(mess)  end
  def do_clearchargingprofile(mess)  end

end

module EvSiTransmiter

  def do_updatefirmware(mess)  end 
  def do_getlocallistversion(mess)  end
  def do_sendlocallist(mess)  end
  def do_getdiagnostics(mess)  end
  def do_changeconfiguration(mess)  end
  def do_getconfiguration(mess)  end
  def do_clearcache(mess)  end
  def do_reset(mess)  end
  
  def do_setchargingprofile(mess)  end
  
  def do_changeavailability(mess)  end
  def do_unlockconnector(mess)  end
  def do_reservenow(mess)  end
  def do_cancelreservation(mess)  end
  def do_remotestarttransaction(mess)  end
  def do_remotestoptransaction(mess)  end
  
  def send_telecommande(name,mess) # done by Ruiby gui
     send_call(name,mess)
  end
  
  def receive_callresult()
    log message.inspect
  end
  def receive_callerror()
    log message.inspect
  end
end

class Evsi 
  include EvSiReceiver
  include EvSiTransmiter
  
  def initialize(cbi,ws)
    @cbi,@ws=cbi,ws
    @idSend=rand(1000..2000)
  end
  def closed()
  end
  
  def log(t) $app.log("[#{@cbi}] #{t}") end
  def get_time(delta=0) (Time.now+delta).to_datetime.rfc3339 end  
  
  #################### CP=>CS ###################
  def receive_call(message)
    begin
      timeout(60) {
        code,id,name,mess=message
        log [code,id,name]
        methode="do_#{name.downcase}"
        response=self.send(methode,mess)
        response ? send_callresult(id,response) : raise("no response to #{name} request")
      }
    rescue Exception => e
      log "#{e}\n  #{e.backtrace.join("\n  ")}"
      send_callerror(message[1]||0,e.to_s)
    end
  end
  def send_callresult(id,message)
    @ws.send(JSON.generate([3,id,message]))
  end
  def send_callerror(id,error)
    @ws.send(JSON.generate([4,id,error.to_s,error.to_s]))
  end
  
  
  #################### CS=>CP ###################
  
  def send_call(reqName,mess)
    @ws.send(JSON.generate([2,@idSend.to_s,reqName,mess]))
    @idSend+=1
  end
end

def httpd_init(app,port)
  ws=WebserverRoot.new(port+1,".","femtows webserver",10,300, {
    "log" => proc {|*par|  File.open("log.txt","a") { |f| f.puts ([Time.now]+par).join(" ")}  },
    "login" => ["basic","admin","saia"]
  } )
  ws.serve("/") {  [200,".html",File.read("content.html").gsub("__PORT__",port.to_s)] }
  app.log("Http serveur on #{port+1} ... ready")
end

class WebSocketServer
  def initialize(app,port)
    @app=app
    @port=port
    @hConnection={}
    @connected=false
    EM::WebSocket.run(:host => "0.0.0.0", :port => port) do |ws|
      log("websocket server run")
      cbi=""
      ws.onopen { |handshake| cbi=onConnected(ws,handshake) rescue log("#{$!}\n  #{$!.backtrace.join("\n  ")}") }
      ws.onclose { onClose(cbi,ws)  rescue log("#{$!}\n  #{$!.backtrace.join("\n  ")}") }
      ws.onmessage { |msg| onMessage(cbi,ws,msg)  rescue log("#{$!}\n  #{$!.backtrace.join("\n  ")}") }
    end
    app.log("WS serveur OCCCP 1.6 JSON on #{port} ... ready")
  end
  def onConnected(ws,handshake)
    cbi=handshake.path[1..-1]
    log "WebSocket connection open from #{handshake.origin}  ===> CBI=#{cbi}"
    @hConnection[cbi]=Evsi.new(cbi,ws);
    cbi
  end
  def onClose(cbi,ws)
    log "Connection closed"
    @hConnection[cbi].closed()
  end
  def onMessage(cbi,ws,msg)
    mess=JSON.parse(msg)
    log "RECEIVED #{mess.inspect}"
    evsi=@hConnection[cbi]
    case mess[0]
      when 2 then evsi.receive_call(mess)
      when 3 then evsi.receive_callresult(mess)
      when 4 then evsi.receive_callerror(mess)
      else
        raise("unknown CALL code  #{mess.inspect}")
    end
  end
  def log(txt)
    puts("WS>"+txt.to_s)
    @app.log(txt.to_s)
  end
  def vie()
      
  end
end


def mlog(*t) $app.instance_eval { mlog(*t) } if $app end
module Ruiby_dsl
    def log(*t) 
       current=$ta.text
       current=current[-1000...-1] if current.size>10_000
       $ta.text="#{current}\n#{Time.now.strftime('%H:%M:%S')} | #{t.join(' ')}" 
    end
end
if ! defined?($first)
  $first=true
  $portWS=ARGV.first
  Ruiby.app(width: 800, height: 300, title: "WSocket serveur ws#{$portWS}") do
    move(30,30)
    def send_message(data)
      mlog "send JSON #{JSON.generate(data)}"
      $ws.send_msg(JSON.generate(data)) if $ws && $ok
    end
    stack do
      labeli "port Websocket #{$portWS}, serveur HTTP sur #{$portWS.to_i+1}"
      separator
      @enttitle=labeli("", font: "Courier bold 14")
      separator
      $ta=text_area(10,100,font: "Courier 10")
      $ta.text=''
      flowi {
        buttoni("Clear",bg: "#CCAABB") { $ta.text='' }
        buttoni("Reload",bg: "#CCAABB") { load(__FILE__) }
        buttoni("Exit",bg: "#CCAABB") { exit!() }
      }
    end
          
    after(1)  {  @wss=WebSocketServer.new(self,$portWS.to_i) ; httpd_init(self,$portWS.to_i)}
    anim(3000) { @wss.vie if @wss } 
  end
end # end if !defined