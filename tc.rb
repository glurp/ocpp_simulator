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
  NAMESPACES='xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ocppCp15="urn://Ocpp/Cp/2012/06/" xmlns:ocppCs15="urn://Ocpp/Cp/2012/06/" xmlns:wsa5="http://www.w3.org/2005/08/addressing"'
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
    param= h[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
    param["CONID"]=1 if param["CONID"]
    puts "\n\n\n#{'*'*20} #{name} #{'*'*20}"
    p param
    puts r.csend(server,name,param) 
  }
else  

  #server="http://localhost:8080/ocpp"  
  puts "Send request #{ARGV[2]} to server #{ARGV[0]} as boxid #{ARGV[1]}..."
  server=ARGV[0]  
  request=ARGV[2].to_sym
  unless $client_cs_to_cp[:config][request]
    puts "request #{request} unknown !"
    puts "Should be one of #{$client_cs_to_cp[:config].keys.map(&:to_s).join(", ")}"
    exit(0)
  end
  r=PostSoapCp.new("HCHARGEBOXID"=>ARGV[1], "HMESSID"=>"A%", "HFROM"=>"http://localhost:9090/ocpp", "HTO"=>server)
  h=$client_cs_to_cp[:config][request]
  param= h[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
  param= param.nearest_merge( Hash[*ARGV[3..-1]] )
  puts  "Parametres : " + param.map {|k,v| "%s => %s" % [k,v] }.join(", ")
  puts r.csend(server,request,param) 
end
end