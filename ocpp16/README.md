OCPP 1.6 JSON
==============


Here simulators for ChargePoint and Scada coommunicating with OCPP-J 1.6, in Ruby and javascript.


* **scada.rb** : Websocket server and Http server:
- http server deliver content.html, whith silulate a ChargePoint communicating in 1.6
- WebsocketServer manage links with one or several Chargepoint (silulate and/or real)
* content.html : one page html application : client websocket, button for danding OCPP request, logs

Usage:
```
> ruby scada.rb port
     port: websocket server  
     port+1 ; port of http server
```

Licenses
========
Free, a beer :)
