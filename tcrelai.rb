######################################################################################
#    tcrelai.rb : 
######################################################################################
#
#                   Serveur OcppTC              Client OCppTC
#                   -------------------     --------------------
#                   |                 |     |                  |
#  Freshmile -----> |ARGV[0]:ARGV[1]  |---> |   ARGV[2]:ARGV[2]|--> Saia
#                   |                 |     |                  |
#                   -------------------     --------------------
#
#
######################################################################################

require_relative 'server.rb' # serveur OcppTC
require_relative 'tc.rb'     # client  OcppTC

#============================================================
#  Client TC : emule une supervision emetrice TC ==> borne
#============================================================
class ClientTC  
  def initialize(server)
    puts "Client to #{server}..."
    @server=server
    @hto=server
    @hfrom ="http://localhost:9090/ocpp"
  end
  def csend(cbi,cmd,args)
    socket=PostSoapCp.new({ 
         "HCHARGEBOXID"=> cbi,
         "HMESSID"     => "A%", 
         "HFROM"       => @hfrom,
         "HTO"         => @hto
    })
    puts "#{'='*20} #{cmd}..."
    estart=Time.now
    response=socket.csend(@server,cmd,args)
    eend=Time.now
    puts "Request Timing: #{(eend.to_f-estart.to_f)*1000} ms \n\n\n"
    response
  end
end

#============================================================
#  Server TC : emule une borne recevant une TC
#============================================================

class ServerTC
  include AppliAbstract
  def initialize(ip,port,client)
    @client=client
    @s=ServerSoapOcpp.new(self,{:ip=> ip, :port=> port})
    p "server start..."
    @s.start
    p "server started !"
  end
  def clearCache(hpara)
    h=@client.csend(hpara['HCHARGEBOXID'],:clearCache)
  end
  def reset(hpara)
    hstatus=@client.csend( hpara['HCHARGEBOXID'],:reset,hpara)
  end
  def changeAvailability(hpara)
    hstatus=@client.csend(hpara['HCHARGEBOXID'],:changeAvailability,hpara) 
  end
  def unlockConnector(hpara)
    hstatus=@client.csend(hpara['HCHARGEBOXID'],:unlockConnector,hpara) 
  end
  def remoteStartTransaction(hpara)
    hstatus=@client.csend(hpara['HCHARGEBOXID'],:remoteStartTransaction,hpara) 
  end
  def remoteStopTransaction(hpara)
    hstatus=@client.csend(hpara['HCHARGEBOXID'],:remoteStopTransaction ,hpara) 
  end
  def wait() @s.join end
end



cli=ClientTC.new("http://#{ARGV[2]}:#{ARGV[3]}/ocpp")
sv=ServerTC.new(ARGV[0],ARGV[1],cli)
sv.wait

