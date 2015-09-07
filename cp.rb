#############################################################################
#  cp.rb : Charge Point simulator
#  can be use directly or via parc_sim.rb
#
#  Usage: 
#    > ruby cp.rb  name   ip        port path    url_server                  c1 c2 c3...
#    > ruby cp.rb  ACT001 localhost 6060 /ocpp   http://localhost:9090/ocpp  1 2 3 4
#
#############################################################################

require_relative 'templatesOCPP.rb'
require_relative 'server.rb'
require_relative 'client.rb'
require "monitor"
require 'time'

class Common
  def nowRfc() Time.now.utc.round.iso8601(3) end
end

#-----------------------------------------------------------------------------
#   Connector : simulation d'un connecteur : 
#                      start/stop charge : auto a la demande (remote...)
#                      consommation energie : energie++x ; x selon envharge/hors charge
#                      en service / hors service : selon commande
#                      alarmes : pas fait !
#-----------------------------------------------------------------------------
class Connector < Common
  attr_reader  :charge,:conid
  PLEIN_ENERGIE=(7000*8) /10 # 7 KM pendant 8h
  
  def log(*a) puts "#{@charge.name}:#{conid}    | #{a.join(' ')}"  end
  def warn(*a) puts "#{@charge.name}:#{conid} ~~~~~ | #{a.join(' ')}"  end
  
  def initialize(conid,server,client,charge)
    @conid,@server,@client,@charge = conid,server,client,charge
    @dde_abort=false
    @state=:init
    @state_es=:init
    @remote_cmd={start: false, stop: false, es: false, hs: false}
    @energie=0
    
    @th_plc=Thread.new do           ############### Top Automate / cycle 100 ms...
      sleep(rand(1))
      st=Time.now
      loop { break if @dde_abort==true ; st=automate(st) }
      log("arret connecteur.")
    end
    log("demarrage connecteur...")
  end
  def shutdown() @dde_abort=true ; end
  def automate(st)
    @stateSav=@state
    top_plc((Time.now - st).to_f)
    if @stateSav!=@state
      log("changeState #{@stateSav} ==> #{@state}  (duree=#{(Time.now-st).to_f} ms)")
      st=Time.now 
    end
    simulation_energie()
    send_meter()
    sleep(0.1)
    st
  end
  
  ######################### TOP_PLC : simlation d'un connecteur ###############
  
  def top_plc(duree)
    case @state 
      when :init
        sendStatusNotification(:available)
        @state=:ready
      when :ready
        @state=:locked if @state_es==:es && rand(1000)>995 && duree>3 && send_authorize()
      when :locked
        if @state_es==:es && ! @remote_cmd[:unlock] && ( @remote_cmd[:start] || (rand(100)>90 && duree>20) )
           ok=send_charging
           if ok
             @state=:charging if ok
             @energie_start = @energie
           else
             log("Charge not accepted by supervision !!")
           end
        end
        @state=:ready if @remote_cmd[:unlock]
      when :charging
        if (rand(100)>98 && duree>20) || (@energie-@energie_start)>= PLEIN_ENERGIE || @state_es==:hs || @remote_cmd[:unlock]  || @remote_cmd[:stop]
           send_stop_charging
           @state= (@state_es==:hs || @remote_cmd[:unlock]) ? :init  : ( :locked )
        end
    end
    
    case @state_es
      when :init
          sendStatusNotification(:available)
          @state_es = :es 
      when :es
        if @remote_cmd[:hs] 
          @state_es=:hs          
          sendStatusNotification(:unavailable)
        end
      when :hs
        if @remote_cmd[:es] 
          @state_es = :es 
          @state=:init
          sendStatusNotification(:available)
        end
    end
    @remote_cmd={}
  end
  
  def simulation_energie()
    # energie Wh= puissance(W) * duree (nb heure)
    # energie Wh= x(W)         * (1/(3600*10))   # energie de x W pendant 100ms
    if @state==:charging
        @tempo_send_energie=30
        @energie+=7000.0/(3600*10) +(rand(100)-50)/36000.0 # 7KW / 100ms
    else
        @tempo_send_energie=60
        @energie+=10.0/(3600*10) + (rand(4)-2)/36000.0     # 10W / 100ms
    end
    #warn("Tempo send Energie",@tempo_send_energie)
  end
  
  ############################# Send...      ######################################
  
  def sendStatusNotification(status)
    p caller
    charge.csend(:statusNotification,{"CONID"=> conid,
      "STATUS"=>case status
        when :available then "Available"
        when :unavaialble then "Unavailable"
        end, 
      "ERRORCODE" => "0",
      "TIMESTAMP" => nowRfc
    })
  end
  
  def send_authorize() charge.csend(:authorize,{"CONID"=> conid,"TAG"=> "12345678" }) end
  def send_charging()  
    ret=charge.csend(:startTransaction,{"CONID"=> conid,
          "TAGID"=> "12345678","TIMESTAMP"=> nowRfc ,"METERSTART"=> @energie.round}) 
    @transactionId=ret["TRANSACID"]
    true
  end
  def send_stop_charging() 
    charge.csend(:stopTransaction,{"TRANSACTIONID"=>@transactionId||"unknown",
        "TAGID"=> "12345678","TIMESTAMP"=> nowRfc ,"METERSTOP"=> @energie.round})
  end
  def send_meter_energie()
    charge.csend(:meterValue,{ 
        "CONID"=> conid, 
        "VALUE"=>@energie.round, 
        "TRANSACTID" => (conid.to_i+rand(100000)*100).to_s, 
        "TIMESTAMP" => nowRfc
    }) 
  end
  def send_meter() 
    now=Time.now
    @last_send_meter||= now
    @tempo_send_energie||=10
    if  @last_send_meter+@tempo_send_energie < now
       send_meter_energie
       @last_send_meter=now
    end
  end  
  
  
  ################# callback receive...
  
  def remoteStopTransaction(para) 
    @remote_cmd[:stop]  = true 
    {}
  end
  def remoteStartTranaction(para) 
    @remote_cmd[:start] = true  
    {}
  end
  def changeAvaillibility(para) 
      on ? @remote_cmd[:es] = true :  @remote_cmd[:hs] = true ; 
      {}
  end
  def unlockConnector(para)
    @remote_cmd[:unlock]  = true
    {}
  end
  
end

#-----------------------------------------------------------------------------
#   Charge : simulation d'une borne (ou d'un maitre de plusieurs bornes/charge)
#-----------------------------------------------------------------------------
class Cp < Common
  include MonitorMixin
  attr_reader  :name,:aConnectorId,:client,:cTM_HEARTBEAT
  
  def initialize(name,ip,port,path,url_server,aConnectorId)
    @name,@ip,@port,@path,@url_server,@aConnectorId = name,ip,port,path,url_server,aConnectorId
    @remote_cmd={diqg: false}
    @cTM_HEARTBEAT=30
    mon_initialize
    @server=ServerSoapOcpp.new(self,{ip: @ip, port:@port, path:@path, url_server: @url_server}) 
    @client=PostSoap.new("HCHARGEBOXID"=>@name, "HMESSID"=>"A%", "HFROM"=>"http://#{@ip}:#{port}#{path}", "HTO"=> @url_server)
  end
  
  def run()
     puts "running CP #{@name} #{@ip}:#{@port}/#{@path} CID=#{@aConnectorId}"
     @dde_abort=false
     log( {"ID"=>@name, "HMESSID"=>"A%", "HFROM"=>"http://#{@ip}:#{@port}#{@path}", "HTO"=> @url_server}.inspect )
     
     @hconnecteur=@aConnectorId.inject({}) { |h,conid|  h[conid]=Connector.new(conid,@server,@client,self) ; h}
     
     @last_mess=Time.now.to_f
     @th_client=Thread.new do ################ emission heartbeat en cas de silence
        send_bootNotification
        while @dde_abort==false 
          send_heartbeat
          sleep(@tempo_hb || 30)
        end
     end
     @server.start
     self
  end
  def log(*a) puts "#{name} |        #{a.join(' ')}"  end
  def warn(*a) puts "#{name} | ~~~~~~~~~~~~~ #{a.join(' ')}"  end
  def shutdown()
    @dde_abort=true
    @th_client.kill rescue nil
    @hconnector.each { |k,c| c.shutdown }
  end
  
  ############################### Receptions .........
  
  def updateFirmware(hpara)           {} end 
  def getLocalListVersion(hpara)      {"LLVV" => "2012"} end
  def dataTransfer(hpara)             {} end
  def getConfiguration(hpara)         {} end
  def clearCache(hpara)               {} end
  def reset(hpara)                    {} end
  def sendLocalList(hpara)            {} end
  def changeConfiguration(hpara)      {} end
  def getDiagnostics(hpara)           {} end
  def changeAvailability(hpara)       @hconnecteur[hpara["CONID"]].changeAvailability(hpara)     end
  def unlockConnector(hpara)          @hconnecteur[hpara["CONID"]].unlockConnector(hpara)        end
  def remoteStartTransaction(hpara)   @hconnecteur[hpara["CONID"]].remoteStartTransaction(hpara) end
  def remoteStopTransaction(hpara)    
     conid= (hpara["TRANSACID"].to_i % 100).to_s
     if  @hconnecteur[conid]
       @hconnecteur[conid].remoteStopTransaction(hpara)  
     else
       warn("remoteStopTransaction for unknown connector : #{hpara.inspect}, send to connid==1 !!")
       @hconnecteur["1"].remoteStopTransaction(hpara)  
     end
  end  
  
  def cancelReservation(hpara)        {} end
  def reserveNow(hpara)               {} end
  
  ############################### Emissions .........
  
  def send_heartbeat()
    return if (@last_mess+cTM_HEARTBEAT) > Time.now.to_f
    synchronize  { @client.csend(@url_server,:hbeat,{})  }
    @last_mess=Time.now.to_f
  end
  def send_bootNotification
     params=[]
     synchronize  {
       params=@client.csend(@url_server,:bootNotification,{
        "VENDOR"=>"Actemium",
        "MODEL"=>"3cv",
        "CPSN"=>"1.0","CBSN"=>"1.0",
        "VERSION"=>"1.0",
        "ICCID"=>"0842","IMSI"=>"291487",
        "METERTYPE"=>"?","METERSN"=>"?"
       }) 
       #warn "Interval HeartBeat :",params["INTERVAL"]
       cTM_HEARTBEAT = params["INTERVAL"] if params["INTERVAL"]
       @last_mess=Time.now.to_f
     }
     params.size>0
  end
  def csend(request,params)
    synchronize  { 
      ret=@client.csend(@url_server,request,params) 
      @last_mess=Time.now.to_f
      return(ret)
    }
  end
  
end

if $0 == __FILE__ 
  if ARGV.size >= 6
    th=Cp.new(ARGV[0],ARGV[1],ARGV[2],ARGV[3],ARGV[4],ARGV[5..-1]).run
    sleep
  else
    puts "Usage:
    > ruby cp.rb  name   ip        port path    url_server                  c1 c2 c3...
    > ruby cp.rb  ACT001 localhost 6061 /ocpp   http://localhost:9090/ocpp  1 2 3 4
    "  
    if true
       th=Cp.new("ACT002","localhost","6061","/ocpp","http://ns308363.ovh.net:6060/ocpp",%w{1}).run
    else
      th=Cp.new("ACT001","localhost","6068","/ocpp","http://localhost:6060/ocpp",%w{1 2}).run
      th=Cp.new("ACT002","localhost","6069","/ocpp","http://localhost:6060/ocpp",%w{1 2}).run
    end
    sleep
  end
end



