######################################################################################
#    tc.rb : client OCPP lien CS=>CP
#            permet d'envoyer des telecommande a une borne (simulation SCADA)
######################################################################################
#
# Usage :
#     ruby [-d] tc.rb
#       envoi toutes les requettes configurées vers  un serveur en http://localhost:6062/ocpp
#
#     ruby [-d] tc.rb  url-chargepoint chargboxId  requestName k1 v1 k2 v2 ...
#
######################################################################################
#
#
######################################################################################
# Exemples :
#
# ruby tc.rb  http://localhost:8080/ocpp  CB1002 remoteStartTransaction CONID 1 TAGID 12345
#
######################################################################################

require 'socket'
require 'timeout'
require 'readline'
require_relative 'templatesOCPP.rb'
require_relative 'client_soap.rb'

class PostSoapCp  < ClientSoap
  NAMESPACES='xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" '
  def initialize(config)
       super($client_cs_to_cp,NAMESPACES,config)
  end

end

if $0==__FILE__
if ARGV.size==0
  server="http://localhost:8080/ocpp"  
  r=PostSoapCp.new("HCHARGEBOXID"=>"CB1000", "HMESSID"=>"A%", "HFROM"=>"http://localhost:9090/ocpp", "HTO"=>"you")
  puts "Requests: #{$client_cs_to_cp[:config].keys.join(", ")}"
  $client_cs_to_cp[:config].each { |name,h| 
    param= h[:params].inject({}) { |hh,k| hh[k] = rand(100000).to_s ; hh}
    param["CONID"]=1 if param["CONID"]
    puts "\n\n\n#{'*'*20} #{name} #{'*'*20}"
    p param
    puts r.csend(server,name,param) 
  }
else  
  if ARGV.size<3
    puts "Usage: #{$0} server cbi request p1 v1 p2 v2 ..."
    exit(1)
  end
  #server="http://localhost:8080/ocpp"  
  server=ARGV[0]  
  charboxid=ARGV[1]
  request=ARGV[2].to_sym
  args=Hash[*ARGV[3..-1]]
  puts "\n\nSend to server #{ARGV[0]}  as boxid #{ARGV[1]} request #{ARGV[2]}"
  puts "   Args= #{args.inspect} ... \n\n"
  unless $client_cs_to_cp[:config][request]
    puts "request #{request} unknown !"
    puts "Should be one of #{$client_cs_to_cp[:config].keys.map(&:to_s).join(", ")}"
    exit(0)
  end
  hh=$client_cs_to_cp[:config][request]
  r=PostSoapCp.new("HCHARGEBOXID"=>charboxid, "HMESSID"=>"A%", "HFROM"=> "http://5.39.17.98:8080/", "HTO"=>server)
  param= hh[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
  param= param.nearest_merge( args )
  puts  "Parametres : " + param.map {|k,v| "%s => %s" % [k,v] }.join(", ")
  puts r.csend(server,request,param) 
end
end