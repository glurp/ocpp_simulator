#######################################################################
# Xml SOAP Requests /Responses templates
#
# data comes from traces of a real Charge, implementing Ocpp 1.5...
#
# LIMITES
#   this version supporte unly static structure of SOAP Request/Response
#   xml received are not verified, we only extract data which is confirgured (tag name or attribute name)
#
#######################################################################
require_relative 'utils.rb'

$cs_to_cp={
 :HEADER=>{"ACTION" => "?" , "HCHARGEBOXID"=>"?", "HMESSID"=>"?", "HRELMESSIDTO" => "?", "HTO"=> "?"},
 :SHEADER=> '<SOAP-ENV:Envelope  xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:ocppCs15="urn://Ocpp/Cp/2012/06/" xmlns:wsa="http://www.w3.org/2005/08/addressing"><SOAP-ENV:Header><wsa:Action>/ACTION</wsa:Action><wsa:RelatesTo RelationshipType="http://www.w3.org/2005/08/addressing/reply">HRELMESSIDTO</wsa:RelatesTo><wsa:To>HTO</wsa:To><wsa:MessageID>HMESSID</wsa:MessageID></SOAP-ENV:Header>',
 reqs:  {
   "updateFirmware" => {
    req: { "t:location" => "LOC" },
    resp: { data: "<SOAP-ENV:Body><ocppCs15:updateFirmwareResponse/></SOAP-ENV:Body></SOAP-ENV:Envelope>" }
   },
   "getLocalListVersion" => {
    resp: {
      data: "<SOAP-ENV:Body><ocppCs15:getLocalListResponse><ocppCs15:listVersion>LLVV</ocppCs15:listVersion></ocppCs15:getLocalListResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>",
      params: ["LLVV"]
    }
   },
   "dataTransfer" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:dataTransfertResponse><ocppCs15:status>Accepted</ocppCs15:status><ocppCs15:data>dddd</ocppCs15:data></ocppCs15:dataTransfertResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "getConfiguration" => {
    req: { "t:Key" => "KEY" },
    resp: { data: "<SOAP-ENV:Body><ocppCs15:getConfigurationResponse><ocppCs15:configurationKey>eeee</ocppCs15:configurationKey></ocppCs15:getConfigurationResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "clearCache" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:clearCacheResponse/></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "reset" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:resetResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:resetResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "sendLocalList" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:sendLocalListResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:sendLocalListResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "changeConfiguration" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:changeConfigurationResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:changeConfigurationResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "getDiagnostics" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:getDiagnosticsResponse><ocppCs15:fileName>toto.html</ocppCs15:fileName></ocppCs15:getDiagnosticsResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "changeAvailability" => {
    req: { "t:connectorId" => "CONID" , "t:type" => "type" },
    resp: { data: "<SOAP-ENV:Body><ocppCs15:changeAvailabilityResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:changeAvailabilityResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "unlockConnector" => {
    req: { "t:connectodId" => "CONID" },
    resp: { data: "<SOAP-ENV:Body><ocppCs15:unlockConnectorResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:unlockConnectorResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "reserveNow" => {
    req: { "t:connectodId" => "CONID", "t:idTag" => "TAGID", "t:reservationId" => "RESID"},
    resp: { data: "<SOAP-ENV:Body><ocppCs15:reserveNowResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:reserveNowResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "cancelReservation" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:cancelReservationResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:cancelReservationResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "remoteStartTransaction" => {
    req: { "t:connectodId" => "CONID", "t:idTag" => "TAGID"},
    resp: { 
      data: "<SOAP-ENV:Body><ocppCs15:remoteStartTransactionResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:remoteStartTransactionResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>",
      params: ["TRANSID"] }
   },
   "remoteStopTransaction" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:remoteStopTransactionResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:remoteStopTransactionResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   }
 }
}


$cp_to_cs={
 :HEADER=>{"ID"=>"", "HMESSID"=>"", "HFROM"=>"", "HTO"=>""},
 :config=>
  {:bootNotification=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/BootNotification</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:bootNotificationRequest><ocppCs15:chargePointVendor>VENDOR</ocppCs15:chargePointVendor><ocppCs15:chargePointModel>MODEL</ocppCs15:chargePointModel><ocppCs15:chargePointSerialNumber>CPSN</ocppCs15:chargePointSerialNumber><ocppCs15:chargeBoxSerialNumber>CBSN</ocppCs15:chargeBoxSerialNumber><ocppCs15:firmwareVersion>VERSION</ocppCs15:firmwareVersion><ocppCs15:iccid>ICCID</ocppCs15:iccid><ocppCs15:imsi>IMSI</ocppCs15:imsi><ocppCs15:meterType>METERTYPE</ocppCs15:meterType><ocppCs15:meterSerialNumber>METERSN</ocppCs15:meterSerialNumber></ocppCs15:bootNotificationRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>
      ["VENDOR",
       "MODEL",
       "CPSN",
       "CBSN",
       "VERSION",
       "ICCID",
       "IMSI",
       "METERTYPE",
       "METERSN"],
      ret: {"s:currentTime"=>"TM", "s:heartbeatInterval" => "INTERVAL"}
   },
   :dataTransfert=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HMESSID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/DataTransfer</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:dataTransferRequest><ocppCs15:vendorId>VENDORID</ocppCs15:vendorId><ocppCs15:messageId>MESSID</ocppCs15:messageId><ocppCs15:data>DATA</ocppCs15:data></ocppCs15:dataTransferRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     params: ["VENDORID", "MESSID", "DATA"],
     ret: {"t:status" => "STATUS"}
      },
   :hbeat=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/Heartbeat</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:heartbeatRequest></ocppCs15:heartbeatRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>[]},
   :authorize=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/Authorize</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:authorizeRequest><ocppCs15:idTag>IDTAG</ocppCs15:idTag></ocppCs15:authorizeRequest></SOAP-ENV:Body></SOAP-ENV:Envelope><SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">gir.vat.mx.014de1</ocppCs15:chargeBoxIdentity><wsa5:MessageID>014de1-20131008112208256-708903</wsa5:MessageID><wsa5:From><wsa5:Address>http://81.56.166.41:8080/ocpp/</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">http://www5.gir.fr/cli-sab-M012354-dbt_demo-v2/ocpp15</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/Authorize</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:authorizeRequest><ocppCs15:idTag>D01ADA94</ocppCs15:idTag></ocppCs15:authorizeRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     params: ["IDTAG"],
     ret: {"t:status" => "TRANSACID" },
     },
   :meterValue=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/MeterValues</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:meterValuesRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:transactionId>TRANSACTID</ocppCs15:transactionId><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value>VALUE</ocppCs15:value></ocppCs15:values></ocppCs15:meterValuesRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>["CONID", "TRANSACTID", "TIMESTAMP", "VALUE"]},
   :meterValues=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/MeterValues</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:meterValuesRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:transactionId>TRANSACTID</ocppCs15:transactionId><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp>XXX</ocppCs15:values></ocppCs15:meterValuesRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>".gsub(/XXX/,
       "<ocppCs15:value measurand=\"Energy.Reactive.Import.Register\">V1</ocppCs15:value><ocppCs15:value measurand=\"Energy.Active.Export.Interval\">V2</ocppCs15:value><ocppCs15:value measurand=\"Energy.Active.Import.Interval\">V3</ocppCs15:value><ocppCs15:value measurand=\"Energy.Reactive.Export.Interval\">V4</ocppCs15:value><ocppCs15:value measurand=\"Energy.Reactive.Import.Interval\">V5</ocppCs15:value><ocppCs15:value measurand=\"Power.Active.Export\">V6</ocppCs15:value><ocppCs15:value measurand=\"Power.Active.Import\">V7</ocppCs15:value><ocppCs15:value measurand=\"Power.Reactive.Export\">V8</ocppCs15:value><ocppCs15:value measurand=\"Power.Reactive.Import\">V9</ocppCs15:value><ocppCs15:value measurand=\"Current.Export\">V10</ocppCs15:value><ocppCs15:value measurand=\"Current.Import\">V11</ocppCs15:value><ocppCs15:value measurand=\"Voltage\">V12</ocppCs15:value><ocppCs15:value measurand=\"Temperature\">V13</ocppCs15:value>"),
     :params=>["CONID", "TRANSACTID", "TIMESTAMP", ]+((1..13).map {|i| "V#{i}"})},
   :statusNotification=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/StatusNotification</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:statusNotificationRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:status>STATUS</ocppCs15:status><ocppCs15:errorCode>ERRORCODE</ocppCs15:errorCode><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp></ocppCs15:statusNotificationRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>["CONID", "STATUS", "ERRORCODE", "TIMESTAMP"]},
   :startTransaction=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/StartTransaction</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:startTransactionRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:idTag>TAGID</ocppCs15:idTag><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:meterStart>METERSTART</ocppCs15:meterStart></ocppCs15:startTransactionRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     params: ["CONID", "TAGID", "TIMESTAMP", "METERSTART"],
     ret: {"t:transactionId" => "TRANSACID" },
   },
   :stopTransaction=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/StopTransaction</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:stopTransactionRequest><ocppCs15:transactionId>TRANSACTIONID</ocppCs15:transactionId><ocppCs15:idTag>TAGID</ocppCs15:idTag><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:meterStop>METERSTOP</ocppCs15:meterStop></ocppCs15:stopTransactionRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>["TRANSACTIONID", "TAGID", "TIMESTAMP", "METERSTOP"]
     }
   }
}
if $0==__FILE__
  require_relative 'client.rb'
  r=PostSoap.new("HCHARGEBOXID"=>"A0022", "HMESSID"=>"A%", "HFROM"=>"me", "HTO"=>"you")
  $cp_to_cs[:config].each { |name,h| 
    param= h[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
    puts "\n\n\n#{'*'*20} #{name} #{'*'*20}"
    p param
    puts r.format(name,param) 
  }
end


