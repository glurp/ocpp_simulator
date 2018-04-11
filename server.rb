######################################################################################
#    server.rb : server OCPP (SOAP) , reccoit des commandes d'un superviseur
#
######################################################################################
#
# Usage :
#   >ruby serveur.rb 8080
#     affiche toutes les requettes recues sur le serveur localhost:8080/ocpp
#
######################################################################################
#  API
#  @s=ServerSoapOcpp.new(appli,{:ip=> "0.0.0.0" , :port=> port})
#
#  appli must include the module AppliAbstract :
#  module AppliAbstract
#    def updateFirmware(pars) end
#    def getLocalListVersion(pars) end
#    ...
#
# 'pars' are Hash of  request parameter
#  methodes must return a hash of data to be send to response
#
# each request (Request/Response) are configured un templatesOCPP.
#
# Exemple :
#   "remoteStartTransaction" => {
#    req: { "t:connectodId" => "CONID", "t:idTag" => "TAGID"},
#    resp: { 
#      data: "<SOAP-ENV:Body><ocppCs15:remoteStartTransactionResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:remoteStartTransactionResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>",
#      params: ["TRANSID"] }
#   },
# reg: hash of data to be extracted from request ( t: tagname , a: attribute name ), values are name of parameter
# used in callback call
# framework will call :  application.remoteStartTransaction( {"CONID"=> 12312, "idTag"=> "012345678" } )
# which should return { "TRANSID" => 0123 }
# 
# Response Header can be configured by modification of :
#    $cs_to_cp[:HEADER]  ; {"HCHARGEBOXID"=>"?", "HMESSID"=>"?", "HRELMESSIDTO" => "?", "HTO"=> "?"},
#    $cs_to_cp[:SHEADER]  ; <SOAP-ENV:Envelope  xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:ocppCs15="urn://Ocpp/Cp/2012/06/" xmlns:wsa="http://www.w3.org/2005/08/addressing"><SOAP-ENV:Header><wsa:Action>/ACTION</wsa:Action><wsa:RelatesTo RelationshipType="http://www.w3.org/2005/08/addressing/reply">HRELMESSIDTO</wsa:RelatesTo><wsa:To>HTO</wsa:To><wsa:MessageID>HMESSID</wsa:MessageID></SOAP-ENV:Header>',
#
######################################################################################
# Exemples :
#
######################################################################################


require 'thread'
require 'socket'

Thread.abort_on_exception=true
BasicSocket.do_not_reverse_lookup = true

require 'timeout'
require 'readline'
#require 'gserver'
require_relative './templatesOCPP.rb'


class ServerSoapOcpp < GServer
  def initialize(application,config)
    super(config[:port],config[:ip])
    @config=config 
    @app=application
    puts "Serveur Ocpp/TCP on #{config[:ip]}:#{config[:port]}...."
  end
  def serve(so)
    serve1(so)
  rescue Exception => e
    puts "#{e} :\n  #{e.backtrace.join("\n   ")}"
  end
  def serve1(so)
    p "connexion... #{so}"
    http_header=nil; timeout(10) { http_header= so.gets("\r\n\r\n")}
    hheader=http_header.split("\r\n").inject({}) { |h,line| k,v=line.split(': ',2); h[k]=v; h}
    len=hheader["Content-Length"].to_i
    puts "reading #{len}..."
    xml=nil; timeout(9) { xml=so.readpartial(len) }
    buff=make_response(hheader,xml)
    unless buff
      puts "no response..."
      return
    end
    hrep="HTTP/1.1 200 OK\r\nContent-Type: application/soap+xml;charset=UTF-8\r\nServer: simulator\r\nContent-Length: #{buff.size}\r\nConnection: close\r\n\r\n"
    so.write( hrep+buff )  
  rescue Exception => e
    puts "\n\n!!!!!  #{e} #{e.backtrace[0..3].join("  ")}\n\n"
  end
  
  def make_response(header,data)
    
    #---------------------        Finding request name
    #  Content-Type: application/soap+xml; action=\"/ChangeAvailability\"; charset=UTF-8\
    
    name,action0=*( header["Content-Type"].split(';').grep(/action=/).first.split('=') )
    action0.gsub!(/[\/"']/,'')
    action= action0[0,1].downcase() + action0[1..-1]
    unless @app.respond_to?(action) && $cs_to_cp[:reqs][action]
      puts "Unknown request : #{action} in application class (or templates)"
      return nil
    end
    
    #---------------- extract datas from Soap header
    # <soap:Envelope ><soap:Header><Action ...>/ChangeAvailability</Action><MessageID ...>d3</MessageID>
    #   <To ...>http://localhost</To><ReplyTo ...><Address>http://www.w3.</Address></ReplyTo>
    #  </soap:Header>
    
    head=data.split(":Header")[1]
    hreq=head.extract_data({"t:MessageID" => "HMESSID","t:chargeBoxIdentity" => "HCHARGEBOXID"})
    hrep=({"HMESSID" => (Time.now.to_f*1000).round,  "HRELMESSIDTO" => hreq["HMESSID"]||"0", "HTO"=> "http://ocpp.server.org","HCHARGEBOXID"=>hreq["HCHARGEBOXID"]})
    
    #---------------------        extract desired data from request
    
    h=$cs_to_cp[:reqs][action]
    params_req= h[:req] ? data.extract_data(h[:req]) : {}
    
    params_req=hrep.merge({ "ACTION" => action0 }).merge(params_req)
    puts "Request : #{params_req.inspect}"
    
    #---------------------  call application , format response
    rep={}
    begin
      rep=@app.send(action,params_req) 
      raise("app response is not Hash") unless Hash === rep
    rescue Exception  => e
      puts "calling app.#{action} : #{e} : \n  #{e.backtrace.join("\n   ")}"
      rep={}
    end
    
    params_reponse = rep 
    h[:resp][:params].each { |k| params_reponse[k]="?" unless params_reponse[k] }  if  h[:resp][:params]
    params_reponse["ACTION"]=action0
    params_reponse=$cs_to_cp[:HEADER].merge(hrep).merge(params_reponse)    
    response = $cs_to_cp[:SHEADER] + h[:resp][:data]
    params_reponse.each { |k,v| response.gsub!(k,v.to_s) }
    puts "Response: #{params_reponse.inspect}"
    params_reponse.each { |k,value| response.sub!(k,value.to_s) }
    response.showXmlData
    
    response
  end  
end

module AppliAbstract
    def updateFirmware(pars) {"STATUS" => "Accepted"} end
    def getLocalListVersion(hpara)  {"STATUS" => "Accepted"} end
    def dataTransfer(hpara)  {"STATUS" => "Accepted"} end
    def getConfiguration(hpara)  {"STATUS" => "Accepted"} end
    def clearCache(hpara)  {"STATUS" => "Accepted"} end
    def reset(hpara)  {"STATUS" => "Accepted"} end
    def sendLocalList(hpara)  {"STATUS" => "Accepted"} end
    def changeConfiguration(hpara)  {"STATUS" => "Accepted"} end
    def getDiagnostics(hpara)  {"STATUS" => "Accepted"} end
    def changeAvailability(hpara)  {"STATUS" => "Accepted"} end
    def unlockConnector(hpara)  {"STATUS" => "Accepted"} end
    def cancelReservation(hpara)  {"STATUS" => "Accepted"} end
    def reserveNow(hpara)  {"STATUS" => "Accepted"} end
    def remoteStartTransaction(hpara)  {"STATUS" => "Accepted"} end
    def remoteStopTransaction(hpara)  {"STATUS" => "Accepted"} end
end

if $0==__FILE__
  Thread.abort_on_exception = true
  class Application 
    include AppliAbstract
    def initialize(port)
      server="http://0.0.0.0:#{port}/ocpp"
      @port=port
      @s=ServerSoapOcpp.new(self,{:ip=> "0.0.0.0" , :port=> port})
      p "start"
      @s.start
      p "started"
    end
    def updateFirmware(hpara)           end
    def getLocalListVersion(hpara)      {"LLVV" => "123456"} end
    def dataTransfer(hpara)             end
    def getConfiguration(hpara)         end
    def clearCache(hpara)               end
    def reset(hpara)                    end
    def sendLocalList(hpara)            end
    def changeConfiguration(hpara)      end
    def getDiagnostics(hpara)           end
    def changeAvailability(hpara)       end
    def unlockConnector(hpara)          end
    def cancelReservation(hpara)       end
    def reserveNow(hpara)               end
    def remoteStartTransaction(hpara)   {"TRANSID"=> Time.now.to_i} end
    def remoteStopTransaction(hpara)    end
    def wait() @s.join end
  end
  
  $cs_to_cp[:HEADER]["HCHARGEBOXID"]= ARGV[1]
  Application.new(ARGV[0].to_i).wait
end
