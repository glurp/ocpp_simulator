OCPP 1.6 JSON
==============


Here simulators for ChargePoint and CentralSystem with OCPP-J 1.6, in Ruby and javascript:
* CS in ruby with GUI
* CP in javascript, via navigator

Main files:

* **scada.rb** : Websocket (OCPP JSON) server and Http server:
1. http server deliver content.html, witch simulate a ChargePoint communicating in 1.6 in a navigator
2. WebsocketServer manage links with one or several Chargepoint (simulate and/or real)
3. proxy OCPP (note ready yet)
* **content.html** : one page html application : client websocket, button for danding OCPP request, logs

Usage:
```
> ruby scada.rb port
     port: websocket server  
     port+1 : port of http server
> ruby scada.rb 6060
> firefox http://localhost:6061/   >>> auto-connect to ws 6060, clock for send request
```



Some tools are provided :
* **ws_sender.rb** : client ws ; connect to server and send messages ( parameters )
* **ws_proxy.rb** : a pure websocket proxy (pure messages routing)
* **mess_generator.rb** : generate typical messages from JSON Schema(s) (see mess.txt,  messages_ocpp-j-1_6.xlsx)

Proxy Usage:
> (ws_sender ocpp request) **==>** proxy **==>** CS

```
> ruby ws_proxy.rb 6060 127.0.0.1 6161
> ruby scada 6161
> ruby ws_send localhost 6060  '[2,0,"Heartbeat",{}]"
```


Status
========

CP->CS tested with real Evsi (Schneider EVLink Wallbox).
scada.rb as proxy : current developping
ws_proxy : done
ws_sender : done

TODO
====
* [ ] commands CS=>CP
* [x] timeout CS=>CP
* [ ] Header client ws with occp1.6 marker
* [ ] GUI plugable
* [ ] ws proxy integrated

Licenses
========
Free, a beer :)
