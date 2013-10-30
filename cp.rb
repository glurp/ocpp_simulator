#############################################################################
#  cp.rb : Charge Point simulator
#  can be use directly or via parc_sim.rb
#
#  Usage: 
#    > ruby cp.rb  name   ip        port path    url_server                  c1 c2 c3...
#    > ruby cp.rb  ACT001 localhost 6060 /ocpp   http://localhost:9090/ocpp  1 2 3 4
#
#############################################################################

require_relative 'templatesOCPP.rb"
require_relative 'server.rb"
require_relative 'client.rb"

class Cp
  TM_HEARTBEAT=30.0
  attr_reader  :name,:aConnectorId
  def initialize(name,ip,port,path,url_server,aConnectorId)
    @name,@ip,@port,@path,@url_server,@aConnectorId=name,ip,port,path,url_server,aConnectorId
    @tempo_hb=30
  end
  def run()
     puts "running CP #{@name} #{@ip}:#{@port}/#{@path} CID=#{@aConnectorId}"
     @dde_abort=false
     @server=ServerSoapOcpp.new(self,{ip: @ip, port:@port, path:@path, url_server: @url_server}) 
     @client=PostSoap.new("ID"=>@name, "HMESSID"=>"A%", "HFROM"=>"http://#{@ip}:#{port}#{path}", "HTO"=> @url_server)
     @last_mess=Time.now.to_f
     @th_client=Thread.new {
        send_bootNotification
        while @dde_abort==false 
          send_hertbeat
          sleep(@tempo_hb)
        end
     }
     @th_plc=new { 
        @state=:init;
        st=Time.now
        while @dde_abort==false
            @stateSav=@state
            top_plc((Time.now-st).to_f)
            st=Time.now if @stateSav!=@state
            sleep(0.1)
        end 
     }
  end
  def shutdown()
    @dde_abort=true
    sleep(3) ; [@th_client,@th_plc].each { |th| th.join } 
  end
  def send_heartbeat()
    return if (@last_mess++TM_HEARTBEAT) > Time.now.to_f
    @client.format(:hertbeat)
    r.send(server,name,{}) 
    @last_mess=Time.now.to_f
  end
  def send_bootNotification
     params=@client.send(server,:bootNotification,{"VENDOR"=>"Actemium","MODEL"=>"3cv","CPSN"=>"1.0","CBSN"=>"1.0","VERSION"=>"1.0","ICCID"=>"0842","IMSI"=>"291487","METERTYPE"=>"?","METERSN"=>"?"}) 
     @tempo_hb = params["INTERVAL"] if params["INTERVAL"]
     params.size>0
  end
  def top_plc(dure)
    case @state 
      when :init
        @state=:ready if send_bootNotification()
      when :ready
        @state=:locked if rand(1000)>995 && send_authorize()
      when :locked
        if rand(100)>80
           send_charging
           @state=:charging
        end
      when :charging
        if rand(100)>99
           send_stop_charging
           @state=:ready
        end
      when :hs
    end
    energie()
  end
  def send_authorize end
  def send_charging end
  def send_stop_charging end
  def send_measures end  
  def energie()
    if @state==:charging
        @energie+=7000.0/(3600*10) # 7Kwh / 100ms
        @puissance=7000
        @temperature+= rand(-2..2)
        @voltage=rand(210..230)
    else
        @energie+=10/(3600*10) # 10W / 100ms
        @puissance=rand(9..11)
        @temperature+= rand(-0.5..0.5)
        @temperature+= [20,30,@temperature].sort[1]
        @voltage=rand(210..230)
    end
  end
end

if $0 == __FILE__ 
  if ARGV.size >= 6
    th=Cp.new(ARGV[0],ARGV[1],ARGV[2],ARGV[3],ARGV[4],ARGV[5..-1]).run
    th.join()
  else
    puts "Usage:
    > ruby cp.rb ACT001 localhost 6060 /ocpp   http://localhost:9090/ocpp  1 2 3 4
    "    
  end
end