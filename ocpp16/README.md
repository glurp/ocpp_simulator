OCPP 1.6 JSON
==============


Here simulators for ChargePoint and Scada communicating with OCPP-J 1.6, in Ruby and javascript.


* **scada.rb** : Websocket (OCPP JSON) server and Http server:
1. http server deliver content.html, whith silulate a ChargePoint communicating in 1.6
2. WebsocketServer manage links with one or several Chargepoint (silulate and/or real)
* **content.html** : one page html application : client websocket, button for danding OCPP request, logs

Usage:
```
> ruby scada.rb port
     port: websocket server  
     port+1 : port of http server
> ruby scada.rb 6060
> firefox http://localhost:6061/
```



Status
========

Testeed between javscript/ruby server.

Server part trested with real Evsi (EVLink Wallbox Schneider).

Licenses
========
Free, a beer :)
