######################################################################################
#    client.rb : client OCPP (SOAP) , interroge le superviseur
#
######################################################################################
#
# Usage :
#     ruby [-d] client.rb
#       envoi toutes les requettes configurées vers  un serveur en http://localhost:6062/ocpp
#
#     ruby [-d] client.rb  url-scada chargpointId  requestName k1 v1 k2 v2 ...
#      envoie une requette a un serveur, avc parametres optionel
#       les parametres non-reseignés sont remplie avec des nombres aleatoires
#
#     -d : affiches les trames SOAP (xml)
#
######################################################################################
#
#  API
#    Declare a connection
#     cli=PostSoap.new("ID"=>"boxIndentity", "HMESSID"=>"A%", "HFROM"=>"http://boxserverip:9090/path-ocpp", "HTO"=>"you")
#
#    use Connection :
#      cli.csend(server,requestName,param) 
#
#    Example. Configuration of startTransaction request :
#   :startTransaction=>
#      {:req=>
#         "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/StartTransaction</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:startTransactionRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:idTag>TAGID</ocppCs15:idTag><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:meterStart>METERSTART</ocppCs15:meterStart></ocppCs15:startTransactionRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
#       :params=>["CONID", "TAGID", "TIMESTAMP", "METERSTART"],
#       :ret=>["t:transactionId" => "TRANSACID" ],
#      },
#  usage :
#   csend( supervsor-url request-name n hash_parameterà
#      which return response datas values
#
#   ret=cli.csend("http://host:6677/ocpp",:startTransaction,{ CONID => 1, "TAGID" => "12345678" , "TIMESTAMP" => "2000-10-30T22:33:01z" })
#   ret=> { "TRANSACID" => 12434 }
#
######################################################################################
# Exemples :
#
# ruby client.rb  http://127.0.0.1:6060/ocpp  CB1002 hbeat
# ruby client.rb  http://ns308363.ovh.net:6060/ocpp   CB1000 startTransaction CONID 1 TAGID 11223344
# ruby client.rb  http://ns308363.ovh.net:6060/ocpp   CB1000 stopTransaction TRANSACTIONID 818101 
# ruby client.rb  http://localhost:6061/ocpp          CB1000 meterValues CONID 1 V1 1 V2 2 V3 3 V4 4 V5 5 V6 6 V7 7 V8 8 V9 9 V10 10 V11 11 V12 12 V13 13 
#
######################################################################################

require 'readline'
require_relative './templatesOCPP.rb'
require_relative 'client_soap.rb'

class PostSoapCs < ClientSoap
    NAMESPACES='xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ocppCp15="urn://Ocpp/Cp/2012/06/" xmlns:ocppCs15="urn://Ocpp/Cs/2012/06/" xmlns:wsa5="http://www.w3.org/2005/08/addressing"'
    def initialize(config)
       super($cp_to_cs,NAMESPACES,config)
    end
end

if $0==__FILE__
if ARGV.size==0
  server="http://localhost:6060/ocpp"  
  r=PostSoapCs.new("HCHARGEBOXID"=>"CB1000", "HMESSID"=>"A%", "HFROM"=>"http://localhost:9090/ocpp", "HTO"=>"you")
  $cp_to_cs[:config].each { |name,h| 
    param= h[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
    param["CONID"]=1 if param["CONID"]
    puts "\n\n\n#{'*'*20} #{name} #{'*'*20}"
    p param
    puts r.csend(server,name,param) 
  }
else  

  #server="http://ns308363.ovh.net:6060/ocpp"  
  puts "Send request #{ARGV[2]} to server #{ARGV[0]} as boxid #{ARGV[1]}..."
  server=ARGV[0]  
  request=ARGV[2].to_sym
  unless $cp_to_cs[:config][request]
    puts "request #{request} unknown !"
    puts "Should be one of #{$cp_to_cs[:config].keys.map(&:to_s).join(", ")}"
    exit(0)
  end
  r=PostSoapCs.new("HCHARGEBOXID"=>ARGV[1], "HMESSID"=>"A%", "HFROM"=>"http://localhost:9090/ocpp", "HTO"=>"http://you.com")
  h=$cp_to_cs[:config][request]
  param= h[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
  param= param.nearest_merge( Hash[*ARGV[3..-1]] )
  puts  "Parametres : " + param.map {|k,v| "%s => %s" % [k,v] }.join(", ")
  puts r.csend(server,request,param) 
end
end