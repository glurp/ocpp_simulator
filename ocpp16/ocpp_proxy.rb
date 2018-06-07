#!/usr/bin/ruby

require 'femtows'
require 'eventmachine'
require 'em-websocket'
require 'em-websocket-client'
require 'Ruiby'
require 'json'

# gem install eventmachine em-websocket 
# gem install femtows Ruiby             # for debug

load 'ocpp_router2.rb'

#############################################################
#   occp_proxy.rb : CS OCPP-J 1.6 : support all scada function + route requests to an other scada OCPPP, if possible
#   Usage :
#     > occp_proxy.rb port  [urlrooter]
#        port   ==> webSocket server port
#        port+1 ==> Http server port
#        urlrooter: if defined, proxy client connection to this ws url
#############################################################

module EvSiReceiver
  #------------------ Requests
  
  def do_bootnotification(mess) 
    asyncRooter("BootNotification",mess)
    {status: "Accepted", currentTime: get_time(), interval: 1800 }  
  end
  def do_datatransfer(mess)     
    asyncRooter("Datatransfer",mess)
    {status: "Accepted"}      
  end
  def do_diagnosticsstatusnotification(mess)  {}          end
  def do_firmwarestatusnotification(mess)     {}          end
  
  def do_heartbeat(mess)        
    asyncRooter("Heartbeat",mess)     
    {currentTime: get_time()} 
  end
  def do_authorize(mess)         
     syncRooter("Authorize",mess,{"idTagInfo":{"status":"Accepted","expiryDate": get_time(1000+24*3600*7)}})
  end
  
  def do_metervalues(mess)        
    asyncRooter("MeterValues",mess)     
    {}                      
  end
  def do_statusnotification(mess) 
    p [@frame,self]
    $app.updateCbiStatus(@cbi,mess) if @frame
    asyncRooter("StatusNotification",mess)     
    {}
  end
  def do_starttransaction(mess,&b)   
    trid=mess["connectorId"].to_i+(Time.now.to_i % 10000)*100
    default={idTagInfo: {status: "Accepted"},transactionId: trid}
    syncRooter("StartTransaction",mess,default,&b)
  end
  def do_stoptransaction(mess)     
    syncRooter("StopTransaction",mess,{idTagInfo: {status: "Accepted"}} )
  end

  
  #?
  def do_triggermessage(mess)  end
  def do_getcompositeschedule(mess)  end
  def do_clearchargingprofile(mess)  end

end

module EvSiTransmiter
=begin
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
=end  

  def send_telecommande(name,mess) # done by Ruiby gui/ application(MQ)
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
    @lastCB=nil

    @router= ($app.hasOcpp16Slave? ) ? Router.new(cbi,self,ARGV[1]) : nil
    
    @frame=$app.respond_to?(:cbiFrame) ? $app.cbiFrame(cbi) : nil
  end
  def closed()
    @router.send_to_routed("close") if @ws
  end
  def dde_close()
    @ws.close() if @ws
    @ws=nil
  end  
  def log(t) $app.log("[#{@cbi}] #{t}") end
  def get_time(delta=0) (Time.now+delta).to_datetime.rfc3339 end  
  
  #################### CP=>CS ###################
  
  def send_reply(id,resp)
    if resp 
      if resp.is_a?(Hash)
         send_callresult(id,resp) 
      else
         send_callerror(id,resp) 
      end
    else
      send_callerror(id,"no response for request '#{message[2]}' !") 
    end  
  end
  
  def receive_call(message)
    begin
        log "REQUEST #{message}"
        code,@id,name,mess=message
        methode="do_#{name.downcase}"
        #-----------------------------------
        response=self.send(methode,mess) {|resp| send_reply(@id,resp) }
        #-----------------------------------
        send_reply(@id,response) if response
    rescue Exception => e
      log "#{e}\n  #{e.backtrace.join("\n  ")}"
      send_callerror(message[1]||0,e.to_s)
    end
  end

  def make_call(id,name,message)  [2,id,name,message]          end
  def make_callresult(id,message) [3,id,message]               end
  def make_callerror(id,error)    [4,id,error.to_s,error.to_s] end
  
  def send_callresult(id,message) 
    m=JSON.generate(make_callresult(id,message))
    log "REPLY #{m}"
    @ws.send(m)
  end
  def send_callerror(id,error)
    m=JSON.generate(make_callerror(id,error))
    log "REPLY-ERROR #{m}"
    @ws.send(m)
  end
  #=========================== router Api ================
  
  def asyncRooter(name,message)
    if @router
       @router.send_to_routed([2,@id,name,message])
     end
  end
  def syncRooter(name,message,default,&b)
    if @router
       @lastCb=b
       @router.send_to_routed([2,@id,name,message])
     else
       default
     end
  end
  def send_from_route(msg) 
    if @lastCb && msg.is_a?(Hash)
      @lastCB.call(msg)
      @lastCB=nil
    else
      if msg.is_a?(Array) 
        send_call(msg)
      else
        log "Unknow message from route : #{msg}" unless  msg.is_a?(String)
      end
    end
  end
  #################### CS=>CP ###################
  
  def send_call(mess)
    return unless @ws
    case mess
      when Array
        m=JSON.generate(mess)
        @idSend=mess[1]
        @ws.send(m) rescue log("error sending  request to client #{m} : #{$!}")
      when Hash
        m=JSON.generate([2,@idSend.to_s,mess])
        @idSend+=1
        @ws.send(m) rescue log("error sending  request to client #{m} : #{$!}")
      when String
        dde_close()
      else
        long "unknown message type #{mess} #{mess.class}"
    end
  end
  
  def receive_callresult(mess)  
    if @router
      @router.send_to_routed(mess)
    end
  end
  def receive_callerror(mess)
    if @router
      @router.send_to_routed(mess)
    end
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
      log("websocket new connection")
      cbi=""
      ws.onopen { |handshake| 
         cbi=onConnected(ws,handshake) rescue log("#{$!}\n  #{$!.backtrace.join("\n  ")}") 
      }
      ws.onclose { 
        onClose(cbi,ws)  rescue log("#{$!}\n  #{$!.backtrace.join("\n  ")}") 
      }
      ws.onmessage { |msg| 
        onMessage(cbi,ws,msg)  rescue log("#{$!}\n  #{$!.backtrace.join("\n  ")}") 
      }
    end
    app.log("WS serveur OCCCP 1.6 JSON on #{port} ... ready")
  end
  def onConnected(ws,handshake)
    cbi=handshake.path[1..-1] 
    $app.updateCbiCom(cbi,true) if $app.respond_to?(:updateCbiCom)
    log "WebSocket connection open from #{handshake.origin}  ===> CBI=#{cbi}"
    @hConnection[cbi]=Evsi.new(cbi,ws);
    cbi
  end
  def onClose(cbi,ws)
    log "Connection closed #{cbi} !"
    $app.updateCbiCom(cbi,false) if $app.respond_to?(:updateCbiCom)
    @hConnection[cbi].closed() if @hConnection[cbi]
  end
  def onMessage(cbi,ws,msg)
    begin 
      mess=JSON.parse(msg)
      #log "RECEIVED #{mess.inspect}"
      evsi=@hConnection[cbi]
      case mess[0]
        when 2 then evsi.receive_call(mess)
        when 3 then evsi.receive_callresult(mess)
        when 4 then evsi.receive_callerror(mess)
        else
          raise("unknown CALL code  #{mess.inspect}")
      end
    rescue Exception => e
      log(e)
      @hConnection[cbi].close()
    end
  end
  def log(txt)
    puts("WS>"+txt.to_s)
    @app.log(txt.to_s)
  end
  def vie()
  end
end

def mlog(*t) 
  if $app  && $app.respond_to?(:log)
    $app.log(*t) 
  else
    puts t.join(" ")
  end
end

module Ruiby_dsl
    def log(*t) 
       current=$ta.text
       current=current[-4000...-1] if current.size>10_000
       mess="#{Time.now.strftime('%H:%M:%S')} | #{t.join(' ')}"
       $ta.text="#{current}\n#{mess}" 
       File.open("log.txt","a+") {|f| f.puts(mess)}
    end
    
    def hasOcpp16Slave?
      ARGV.size>1
    end
    
    #================= CBI frame
    def cbiFrame(cbi)
      unless @hCbiFr[cbi]
        append_to(@cbifr) { frame("CBI #{cbi}") {stack { 
          @hCbiFr[cbi]={}
          3.times { |con|
            hw={}
            flowi {
              hw["con"]=labeli("")
              hw["com"]=labeli("Connected") if con==0
              hw["status"]=labeli("")
              hw["errorCode"]=labeli("")
              hw["vendorErrorCode"]=labeli("")
            }
            @hCbiFr[cbi][con]=hw
          }
        } } }
      end
      true
    end
    
    # {"connectorId":"2","errorCode":"ConnectorLockFailure","info":"A","status":"Available","timestamp":"2018-06-05T15:50:28+02:00","vendorId":"ID9876","vendorErrorCode":"1"}
    # {"com":"Connected"} 
    def updateCbiStatus(cbi,hm)
      h=hm.clone
      nocon=(h["connectorId"]||"0").to_i
      h["con"]=(nocon==0) ? "Brn" : "C#{nocon}"
      h["errorCode"]="" if h["errorCode"] && h["errorCode"]=="NoError" 
      if @hCbiFr[cbi] && @hCbiFr[cbi][nocon]
          @hCbiFr[cbi][nocon].each {|k,lab| lab.text=disp(h,k,"#{k[0..2]}=") }
      end
    end
    
    def disp(h,k,label) (h[k] && h[k].to_s.size>0) ? " #{h[k]}" : "" end
    
    def updateCbiCom(cbi,state) 
      updateCbiStatus(cbi,{"com" => (state ? "Connected" : "?-?") }) 
    end
end

if defined?($first)
  $app.instance_eval {@hCbiFr={}; clear(@cbifr) }
end


if ! defined?($first)
  $first=true
  $portWS=ARGV.first
  Ruiby.app(width: 800, height: 300, title: "WSocket serveur ws#{$portWS}") do
    move(30,30)
    @hCbiFr={}
    def send_message(data)
      mlog "send JSON #{JSON.generate(data)}"
      $ws.send_msg(JSON.generate(data)) if $ws && $ok
    end
    stack do
      labeli "port Websocket #{$portWS}, serveur HTTP sur #{$portWS.to_i+1}"
      separator
      stacki { scrolled(800,100) { @cbifr=flowi { } } }
      separator
      stack { $ta=text_area(30,100,{:font=>"Courier new 8", :bg => "#133", :fg=> "#FF0"})  }
      $ta.text=''
      flowi {
        buttoni("Clear") { $ta.text='' }
        buttoni("Reload") { load(__FILE__) }
        buttoni("Exit") { exit!() }
      }
    end
          
    after(1)  {  @wss=WebSocketServer.new(self,$portWS.to_i) ; httpd_init(self,$portWS.to_i) ; log("Ready to root to #{ARGV[1]}") if ARGV.size>1}
    anim(3000) { @wss.vie if @wss } 
  end
end # end if !defined