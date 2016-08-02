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
#Serveur Telecommande : 
#   decrit les arguments a extraire (req:), 
#    la reponse a emettre (resp.data, avec des arguments resp.param)

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
   "sendLocalList" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:sendLocalListResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:sendLocalListResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "changeConfiguration" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:changeConfigurationResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:changeConfigurationResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "getDiagnostics" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:getDiagnosticsResponse><ocppCs15:fileName>toto.html</ocppCs15:fileName></ocppCs15:getDiagnosticsResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   
   
   "clearCache" => {
    resp: { 
      req: { },
      data: "<SOAP-ENV:Body><ocppCs15:clearCacheResponse><ocppCs15:status>STATUS</ocppCs15:status></ocppCs15:clearCacheResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", 
      params: ["STATUS"]
    }
   },
   "reset" => {
    req: { "t:type" => "TYPE"  },
    resp: { 
      params: ["STATUS"],
      data: "<SOAP-ENV:Body><ocppCs15:resetResponse><ocppCs15:status>STATUS</ocppCs15:status></ocppCs15:resetResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", 
    }
   },
   "changeAvailability" => {
    req: { "t:connectorId" => "CONID" , "t:type" => "TYPE" },
    resp: { 
      params: ["STATUS"],
      data: "<SOAP-ENV:Body><ocppCs15:changeAvailabilityResponse><ocppCs15:status>STATUS</ocppCs15:status></ocppCs15:changeAvailabilityResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "unlockConnector" => {
    req: { "t:connectorId" => "CONID" },
    resp: { 
      params: ["STATUS"],
      data: "<SOAP-ENV:Body><ocppCs15:unlockConnectorResponse><ocppCs15:status>STATUS</ocppCs15:status></ocppCs15:unlockConnectorResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "remoteStartTransaction" => {
    req: { "t:connectorId" => "CONID", "t:idTag" => "TAGID"},
    resp: { 
      data: "<SOAP-ENV:Body><ocppCs15:remoteStartTransactionResponse><ocppCs15:status>STATUS</ocppCs15:status></ocppCs15:remoteStartTransactionResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>",
      params: ["STATUS"] 
    }
   },
   "remoteStopTransaction" => {
    req: { "t:transactionId" => "TRANSACID"},
    resp: { 
      params: ["STATUS"],
      data: "<SOAP-ENV:Body><ocppCs15:remoteStopTransactionResponse><ocppCs15:status>STATUS</ocppCs15:status></ocppCs15:remoteStopTransactionResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "reserveNow" => {
    req: { "t:connectodId" => "CONID", "t:idTag" => "TAGID", "t:reservationId" => "RESID"},
    resp: { 
      params: ["STATUS"],
      data: "<SOAP-ENV:Body><ocppCs15:reserveNowResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:reserveNowResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   },
   "cancelReservation" => {
    resp: { data: "<SOAP-ENV:Body><ocppCs15:cancelReservationResponse><ocppCs15:status>Accepted</ocppCs15:status></ocppCs15:cancelReservationResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>", }
   }
 }
}

$client_cs_to_cp={
 :HEADER=>{"ACTION" => "?" , "HCHARGEBOXID"=>"?", "HMESSID"=>"?", "HTO"=> "?"},
 :config=>
  {  :reset =>
    {:req=> '<soap:Envelope ><soap:Header><chargeBoxIdentity xmlns="urn://Ocpp/Cp/2012/06/">HCHARGEBOXID</chargeBoxIdentity><Action xmlns="http://www.w3.org/2005/08/addressing">/Reset</Action><MessageID xmlns="http://www.w3.org/2005/08/addressing">urn:uuid:HMESSID</MessageID><To xmlns="http://www.w3.org/2005/08/addressing">HTO</To><ReplyTo xmlns="http://www.w3.org/2005/08/addressing"><Address>http://www.w3.org/2005/08/addressing/anonymous</Address></ReplyTo></soap:Header><soap:Body><resetRequest xmlns="urn://Ocpp/Cp/2012/06/"><type>TYPE</type></resetRequest></soap:Body></soap:Envelope>',
     params: ["TYPE"],
     ret: {"t:status" => "STATUS" },
     },
  :remoteStopTransaction => {:req=> 
  '<soap:Envelope ><soap:Header><chargeBoxIdentity xmlns="urn://Ocpp/Cp/2012/06/">HCHARGEBOXID</chargeBoxIdentity><Action xmlns="http://www.w3.org/2005/08/addressing">/RemoteStopTransaction</Action><MessageID xmlns="http://www.w3.org/2005/08/addressing">urn:uuid:HMESSID</MessageID><To xmlns="http://www.w3.org/2005/08/addressing">HTO</To><ReplyTo xmlns="http://www.w3.org/2005/08/addressing"><Address>http://www.w3.org/2005/08/addressing/anonymous</Address></ReplyTo></soap:Header><soap:Body><remoteStopTransactionRequest xmlns="urn://Ocpp/Cp/2012/06/"><transactionId>TRANSACID</transactionId></remoteStopTransactionRequest></soap:Body></soap:Envelope>',
     params: ["TRANSACID"],
     ret: {"t:status" => "STATUS" },
     },
  :changeConfiguration  =>{:req=> 
  '<soap:Envelope ><soap:Header><chargeBoxIdentity xmlns="urn://Ocpp/Cp/2012/06/">HCHARGEBOXID</chargeBoxIdentity><Action xmlns="http://www.w3.org/2005/08/addressing">/ChangeConfiguration</Action><MessageID xmlns="http://www.w3.org/2005/08/addressing">urn:uuid:HMESSID</MessageID><To xmlns="http://www.w3.org/2005/08/addressing">HTO</To><ReplyTo xmlns="http://www.w3.org/2005/08/addressing"><Address>http://www.w3.org/2005/08/addressing/anonymous</Address></ReplyTo></soap:Header><soap:Body><changeConfigurationRequest xmlns="urn://Ocpp/Cp/2012/06/"><key>KEY</key><value>VALUE</value></changeConfigurationRequest></soap:Body></soap:Envelope>
',
     params: ["KEY","VALUE"],
     ret: {"t:status" => "STATUS" },
     },
   :remoteStartTransaction  =>  {:req=>
   '<soap:Envelope ><soap:Header><chargeBoxIdentity xmlns="urn://Ocpp/Cp/2012/06/">HCHARGEBOXID</chargeBoxIdentity><Action xmlns="http://www.w3.org/2005/08/addressing">/RemoteStartTransaction</Action><MessageID xmlns="http://www.w3.org/2005/08/addressing">urn:uuid:HMESSID</MessageID><To xmlns="http://www.w3.org/2005/08/addressing">HTO</To><ReplyTo xmlns="http://www.w3.org/2005/08/addressing"><Address>http://www.w3.org/2005/08/addressing/anonymous</Address></ReplyTo></soap:Header><soap:Body><remoteStartTransactionRequest xmlns="urn://Ocpp/Cp/2012/06/"><idTag>TAGID</idTag><connectorId>CONID</connectorId></remoteStartTransactionRequest></soap:Body></soap:Envelope>',
     params: ["CONID","TAGID"],
     ret: {"t:status" => "STATUS" },
     },
    :unlockConnector  =>  {:req=> '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Header><chargeBoxIdentity xmlns="urn://Ocpp/Cp/2012/06/">HCHARGEBOXID</chargeBoxIdentity><Action xmlns="http://www.w3.org/2005/08/addressing">/UnlockConnector</Action><MessageID xmlns="http://www.w3.org/2005/08/addressing">urn:uuid:HMESSID</MessageID><To xmlns="http://www.w3.org/2005/08/addressing">HTO</To><ReplyTo xmlns="http://www.w3.org/2005/08/addressing"><Address>http://www.w3.org/2005/08/addressing/anonymous</Address></ReplyTo></soap:Header><soap:Body><unlockConnectorRequest xmlns="urn://Ocpp/Cp/2012/06/"><connectorId>CONID</connectorId></unlockConnectorRequest></soap:Body></soap:Envelope>',
     params: ["CONID"],
     ret: {"t:status" => "STATUS" },
     },
    :changeAvailability  =>  {:req=> '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Header><chargeBoxIdentity xmlns="urn://Ocpp/Cp/2012/06/">HCHARGEBOXID</chargeBoxIdentity><Action xmlns="http://www.w3.org/2005/08/addressing">/ChangeAvailability</Action><MessageID xmlns="http://www.w3.org/2005/08/addressing">urn:uuid:HMESSID</MessageID><To xmlns="http://www.w3.org/2005/08/addressing">HTO</To><ReplyTo xmlns="http://www.w3.org/2005/08/addressing"><Address>http://www.w3.org/2005/08/addressing/anonymous</Address></ReplyTo></soap:Header><soap:Body><changeAvailabilityRequest xmlns="urn://Ocpp/Cp/2012/06/"><connectorId>CONID</connectorId><type>TYPE</type></changeAvailabilityRequest></soap:Body></soap:Envelope>',
     params: ["CONID","TYPE"], # Operative/Inoperative
     ret: {"t:status" => "STATUS" },
     },
    :clearCache  =>  {:req=> '<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:ns1="urn://Ocpp/Cp/2012/06/" xmlns:ns2="http://www.w3.org/2005/08/addressing"><env:Header><ns2:MessageID>urn:uuid:HMESSID</ns2:MessageID><ns2:To env:mustUnderstand="true">HTO</ns2:To><ns2:From env:mustUnderstand="true">HFROM</ns2:From><ns1:chargeBoxIdentity>HCHARGEBOXID</ns1:chargeBoxIdentity><ns2:Action>/ClearCache</ns2:Action></env:Header><env:Body><ns1:clearCacheRequest/></env:Body></env:Envelope>
',
     params: [],
     ret: {"t:status" => "STATUS" },
     },
    :getDiagnostics => { :req=> '<sooap:Envelope xmlns:sooap="http://www.w3.org/2003/05/soap-envelope"  xmlns:ns1="urn://Ocpp/Cp/2012/06/" xmlns:ns2="http://www.w3.org/2005/08/addressing"><sooap:Header><ns2:MessageID>urn:uuid:HMESSID</ns2:MessageID><ns2:To>HTO</ns2:To><ns2:From>HFROM</ns2:From><ns1:chargeBoxIdentity>HCHARGEBOXID</ns1:chargeBoxIdentity><ns2:Action>/GetDiagnostics</ns2:Action></sooap:Header><sooap:Body><ns1:getDiagnosticsRequest><ns1:location>LOCATION</ns1:location></ns1:getDiagnosticsRequest></sooap:Body></sooap:Envelope>',
       params: ["LOCATION"],
       ret: {"t:status" => "STATUS" },
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
      ret: {"t:currentTime"=>"TM", "t:heartbeatInterval" => "INTERVAL"}
   },
   :dataTransfert=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HMESSID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/DataTransfer</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:dataTransferRequest><ocppCs15:vendorId>VENDORID</ocppCs15:vendorId><ocppCs15:messageId>MESSID</ocppCs15:messageId><ocppCs15:data>DATA</ocppCs15:data></ocppCs15:dataTransferRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     params: ["VENDORID", "MESSID", "DATA"],
     ret: {"t:status" => "STATUS"}
      },
   :hbeat2=>
    {:req=>
       '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ocppCp15="urn://Ocpp/Cp/2012/06/" xmlns:ocppCs15="urn://Ocpp/Cs/2012/06/" xmlns:wsa5="http://www.w3.org/2005/08/addressing"><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand="true">ACT001</ocppCs15:chargeBoxIdentity><wsa5:MessageID>01c9c6-20131108141114117-059415</wsa5:MessageID><wsa5:From><wsa5:Address>http://90.94.144.206:8080/ocpp</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand="true">http://ns308363.ovh.net:6060/ocpp</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand="true">/Heartbeat</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:heartbeatRequest></ocppCs15:heartbeatRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>',
      ret: {"t:timestamp" => "TIME" },
     :params=>[]},
   :hbeat=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/Heartbeat</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:heartbeatRequest></ocppCs15:heartbeatRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>[]},
   :authorize=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From>HFROM</wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/Authorize</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:authorizeRequest><ocppCs15:idTag>IDTAG</ocppCs15:idTag></ocppCs15:authorizeRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     params: ["IDTAG"],
     ret: {"t:status" => "TRANSACID" },
     },
    :meterValue=>   {:req=>    '<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity>HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>urn:uuid:HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:ReplyTo><wsa5:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa5:Address></wsa5:ReplyTo><wsa5:To SOAP-ENV:mustUnderstand="true">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand="true">/MeterValues</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:meterValuesRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:transactionId>TRANSACTID</ocppCs15:transactionId><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value>VALUE</ocppCs15:value><ocppCs15:value>VALUE</ocppCs15:value><ocppCs15:value>VALUE</ocppCs15:value><ocppCs15:value>VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register" format="Raw" context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register" format="Raw" context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet"  format="Raw" >VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register" format="Raw" context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register" format="Raw" context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register"  context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register" format="Raw" context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register"  context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value unit="Wh" location="Outlet" measurand="Energy.Active.Import.Register" format="Raw" context="Sample.Periodic">VALUE</ocppCs15:value></ocppCs15:values></ocppCs15:meterValuesRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>',
     :params=>["CONID", "TRANSACTID", "TIMESTAMP", "VALUE"]
    },
    :meterValue2=>   {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/MeterValues</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:meterValuesRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:transactionId>TRANSACTID</ocppCs15:transactionId><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp><ocppCs15:value>VALUE</ocppCs15:value></ocppCs15:values></ocppCs15:meterValuesRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>["CONID", "TRANSACTID", "TIMESTAMP", "VALUE"]},
   :meterValues=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/MeterValues</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:meterValuesRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:transactionId>TRANSACTID</ocppCs15:transactionId><ocppCs15:values><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp>XXX</ocppCs15:values></ocppCs15:meterValuesRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>".gsub(/XXX/,
       "<ocppCs15:value measurand=\"Energy.Reactive.Import.Register\">V1</ocppCs15:value><ocppCs15:value measurand=\"Energy.Active.Export.Interval\">V2</ocppCs15:value><ocppCs15:value measurand=\"Energy.Active.Import.Interval\">V3</ocppCs15:value><ocppCs15:value measurand=\"Energy.Reactive.Export.Interval\">V4</ocppCs15:value><ocppCs15:value measurand=\"Energy.Reactive.Import.Interval\">V5</ocppCs15:value><ocppCs15:value measurand=\"Power.Active.Export\">V6</ocppCs15:value><ocppCs15:value measurand=\"Power.Active.Import\">V7</ocppCs15:value><ocppCs15:value measurand=\"Power.Reactive.Export\">V8</ocppCs15:value><ocppCs15:value measurand=\"Power.Reactive.Import\">V9</ocppCs15:value><ocppCs15:value measurand=\"Current.Export\">V10</ocppCs15:value><ocppCs15:value measurand=\"Current.Import\">V11</ocppCs15:value><ocppCs15:value measurand=\"Voltage\">V12</ocppCs15:value><ocppCs15:value measurand=\"Temperature\">V13</ocppCs15:value>"),
     :params=>["CONID", "TRANSACTID", "TIMESTAMP", ]+((1..13).map {|i| "V#{i}"})},
   :statusNotification=>
    {:req=>
      "<SOAP-ENV:Envelope ><SOAP-ENV:Header><ocppCs15:chargeBoxIdentity SOAP-ENV:mustUnderstand=\"true\">HCHARGEBOXID</ocppCs15:chargeBoxIdentity><wsa5:MessageID>HMESSID</wsa5:MessageID><wsa5:From><wsa5:Address>HFROM</wsa5:Address></wsa5:From><wsa5:To SOAP-ENV:mustUnderstand=\"true\">HTO</wsa5:To><wsa5:Action SOAP-ENV:mustUnderstand=\"true\">/StatusNotification</wsa5:Action></SOAP-ENV:Header><SOAP-ENV:Body><ocppCs15:statusNotificationRequest><ocppCs15:connectorId>CONID</ocppCs15:connectorId><ocppCs15:status>STATUS</ocppCs15:status><ocppCs15:errorCode>ERRORCODE</ocppCs15:errorCode><ocppCs15:vendorErrorCode>VENDORERROR_CODE</ocppCs15:vendorErrorCode><ocppCs15:timestamp>TIMESTAMP</ocppCs15:timestamp></ocppCs15:statusNotificationRequest></SOAP-ENV:Body></SOAP-ENV:Envelope>",
     :params=>["CONID", "STATUS", "ERRORCODE", "VENDORERROR_CODE","TIMESTAMP"]},
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


