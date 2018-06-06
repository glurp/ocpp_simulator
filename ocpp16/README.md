OCPP 1.6 JSON
==============


Here simulators for ChargePoint and Scada communicating with OCPP-J 1.6, in Ruby and javascript:
* CS in ruby with GUI
* CP in jacascrip; via navigator


* **scada.rb** : Websocket (OCPP JSON) server and Http server:
1. http server deliver content.html, whith silulate a ChargePoint communicating in 1.6
2. WebsocketServer manage links with one or several Chargepoint (simulate and/or real)
* **content.html** : one page html application : client websocket, button for danding OCPP request, logs

Usage:
```
> ruby scada.rb port
     port: websocket server  
     port+1 : port of http server
> ruby scada.rb 6060
> firefox http://localhost:6061/
```

Some tools are provided :
* **ws_sender** : client ws ; connect to server and send messages ( parameters )
* **ws_proxy** : a pure websocket proxy
* **mess_generator.rb** : generate (typical) messages from JSON Schema (see mess.txt,  messages_ocpp-j-1_6.xlsx)

Status
========

CP->CS tested with real Evsi (Schneider EVLink Wallbox).

TODO
====
[ ] commands CS=>CP
[ ] timeout CS=>CP
[ ] Header ws with occp1.6 marker
[ ] GUI plugable
[ ] ws proxy integrated

Licenses
========
Free, a beer :)
