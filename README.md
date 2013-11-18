ocpp_simulator
==============

Simulator of a Charge Point via OCPP protocol

SOAP is used via xml templates, so this gem do not depend on any soap stack ...

4 usages :
* client.rb : invoke CP->CS dialog. Alone can invoke a SOAP request to a scada
* server.rb : serve a CS->CP dialog. Alone it print request/responses,  responses are always status=Accepted. 
              server api : invoke a client callback foreach request received
* cp.rb : simulate one Charge Point with multiple connectorId, use client.rb and serveur.rb for 
  scada dialogs, make some start/stop transactions, some notifications.
* parc_sim.rb : simulate a set of charge point.
 

Client
======

Examples :

    >ruby client.rb  http://ns8363.ovh.net:6060/ocpp   CB1000 bootNotification
    >ruby client.rb  http://ns8363.ovh.net:6060/ocpp   CB1002 hbeat
    >ruby client.rb  http://ns8363.ovh.net:6060/ocpp   CB1002 dataTransfert
    >ruby client.rb  http://ns8363.ovh.net:6060/ocpp   CB1001 meterValue
    >ruby client.rb  http://ns8363.ovh.net:6060/ocpp   CB1000 startTransaction CONID 1
    >ruby client.rb  http://ns8363.ovh.net:6060/ocpp   CB1000 startTransaction CONID 1 TAGID 11223344
    >ruby client.rb  http://ns8363.ovh.net:6060/ocpp   CB1000 stopTransaction TRANSACTIONID 818101 

    >ruby  server.rb  8080 &

    >ruby client.rb  http://localhost:6061/ocpp   CB1000  meterValues CONI 1 V1 1 V2 2 V3 3 V4 4 V5 5 V6 6 V7 7 V8 8 V9 9 V10 10 V11 11 V12 12 V13 13 
    >ruby client.rb  http://localhost:6060/ocpp CB1000  startTransaction  CONID 1   TAGID 12345678 METERSTART 11 
    >ruby client.rb  http://localhost:6060/ocpp CB1000  stopTransaction TRANSACIF 765701  METERSTOP 23 
    >ruby client.rb  http://localhost:6060/ocpp CB1000  statusNotification CONID 1 STATUS Faulted ERRORC PowerMeterFailure 
    >ruby client.rb  http://localhost:6060/ocpp CB1000  statusNotification CONID 1 STATUS Faulted ERRORC NoError 

Server
=====

traces exemples (with -d) :
```
>>
"connexion... #<TCPSocket:0x357b7a8>"
"reading 757..."
Request : {"ACTION"=>"ChangeConfiguration"}
Response: {"ACTION"=>"ChangeConfiguration", "HCHARGEBOXID"=>nil, "HMESSID"=>1383169016773, "HRELMESSIDTO"=>"urn:uuid:dd6f6442-a5e7-4055-84fd-ac9174005674", "HTO"=>"http://ocpp.server.org"}
data : <<
  wsa:Action                     /ChangeConfiguration
  wsa:RelatesTo                  urn:uuid:dd6f6442-a5e7-4055-84fd-ac9174005674
  wsa:To                         http://ocpp.server.org
  wsa:MessageID                  1383169016773
  ocppCs15:status                Accepted
>>
"connexion... #<TCPSocket:0x3578e38>"
"reading 875..."
Request : {"ACTION"=>"GetDiagnostics"}
Response: {"ACTION"=>"GetDiagnostics", "HCHARGEBOXID"=>nil, "HMESSID"=>1383169016783, "HRELMESSIDTO"=>"urn:uuid:68f17156-8a2a-4dba-a53e-90e42eb3059c", "HTO"=>"http://ocpp.server.org"}
data : <<
  wsa:Action                     /GetDiagnostics
  wsa:RelatesTo                  urn:uuid:68f17156-8a2a-4dba-a53e-90e42eb3059c
  wsa:To                         http://ocpp.server.org
  wsa:MessageID                  1383169016783
  ocppCs15:fileName              toto.html
>>
"connexion... #<TCPSocket:0x35860e0>"
"reading 731..."
Request : {"ACTION"=>"UnlockConnector", "CONID"=>nil}
Response: {"ACTION"=>"UnlockConnector", "HCHARGEBOXID"=>nil, "HMESSID"=>1383169095099, "HRELMESSIDTO"=>"urn:uuid:e245a17c-f301-4815-b2cd-b6d2fba7c39d", "HTO"=>"http://ocpp.server.org"}
data : <<
  wsa:Action                     /UnlockConnector
  wsa:RelatesTo                  urn:uuid:e245a17c-f301-4815-b2cd-b6d2fba7c39d
  wsa:To                         http://ocpp.server.org
  wsa:MessageID                  1383169095099
  ocppCs15:status                Accepted
>>
```


CP : simulation of a ChargePoint
=============================== 
Usage: 
    > ruby cp.rb  name    ip        port path    url_server                  c1 c2 c3...
    > ruby cp.rb  SIEM001 localhost 6061 /ocpp   http://localhost:9090/ocpp  1 2 3 4

What is simulate:
* boot, lock , ask autorize, start charge, stop charge : autonomous (tempo/random/duration)
* energies imported, send it by meterValues periodicly
* start / stop charge by remote commande (suppose that (transactionId%100) => connectorId !!)
* change Availlibility by remote commande (Inoperative ==> reboot)

What is missing:
* statusNotification with errorCode
* diagnostic, dataTransfered,updateFirmware (!), getConfiguration,reset, 
* localList of tag (the tag is alays the same : '12345678')
* reservation


Parc_sim
========
Create a bunch of ChargePoint
       > ruby parc._simrb  nb ip  port0 path  url_server  nb_connector_by_cp

Configuration
=============

All requests/responses are configured in templateOCPP.rb

Client : each SOAP request/response are configured with
* request: xml template to send, each 'value' place are represented  with a key
* request: list the  key in request (replace strings) to be use a parameters
* response : list of filter of value to extract from request

Server : each SOAP request/response are configured with
* request: hash of  'xpath' to be use for extract data, value of hash are varnames. So a request
  received is represented by a hash of varname=>value 
* response : (as request of client) : string template, list of key

LIMITATION !!! : all that SOAP stuff work only with xml with statics structure !
* you can't extract a list of tagid received from CS
* you can't send a free list of meter

