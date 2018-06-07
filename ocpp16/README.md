OCPP 1.6 JSON
==============


Here simulators for ChargePoint and CentralSystem with OCPP-J 1.6, in Ruby and javascript:
* CS in ruby with GUI
* CP in javascript, via navigator

Main files:

* **scada.rb** : Websocket (OCPP JSON) server and Http server:
1. http server deliver content.html, witch simulate a ChargePoint communicating in 1.6 in a navigator
2. WebsocketServer manage links with one or several Chargepoint (simulate and/or real)
* **content.html** : one page html application : client websocket, button for danding OCPP request, logs
* **ocpp_proxy.rb** and **ocpp_router2.rb** a connector for CS communications  server and client, with redirection to other CS (as client)

Usage scada.rb:
```
> ruby scada.rb port
     port: websocket server  
     port+1 : port of http server

> rubyw scada.rb 6060
> firefox http://localhost:6061/   >>> auto-connect to ws 6060, clock for send request
```

Usage ocpp_proxy.rb:
```
> rubyw scada.rb 3400
> rubyw ocpp_proxy.rb 3300 ws://localhost:3400
> ruby ws_sender.rb  ws://127.0.0.1:3300/BB '[2,"2","StatusNotification",{"connectorId":2,"errorCode":"GroundFailure","status":"Availlable"}]'
```




Some tools are provided :
* **ws_sender.rb** : client ws ; connect to server and send messages ( parameters )
* **ws_proxy.rb** : a pure websocket proxy (pure messages routing)
* **mess_generator.rb** : generate typical messages from JSON Schema(s) (see mess.txt,  messages_ocpp-j-1_6.xlsx)



Status
========

CP->CS tested with real Evsi (Schneider EVLink Wallbox).


TODO
====

* [x] timeout CS=>CP
* [x] GUI plugable for ocpp_proxy
* [x] ws proxy integrated
* [ ] commands CS=>CP
* [ ] Header client ws with occp1.6 marker

