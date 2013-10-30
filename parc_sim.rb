#############################################################################
#  park.rb : park VE Charge simulator
#  OCPP 1.5
#  Usage: 
#    > ruby parc.rb  nb ip        port0 path   url_server   nb_connector_by_cp
#    > ruby parc.rb  10 localhost 6060 /ocpp   http://localhost:9090/ocpp  1 2 3 4
#############################################################################

require_relative 'cp.rb'

if ARGV.size!=6
  puts "Usage: 
    > ruby parc.rb  nb ip        port0 path   url_server   nb_connector_by_cp
    > ruby parc.rb  10 localhost 6060 /ocpp   http://localhost:9090/ocpp  1 2 3 4
  "
  exit!(1)  
end

nb,ip,port0,path,url_server,nb_connector_by_cp = *ARGV
nb=nb.to_i
port0=port0.to_i
nb_connector_by_cp=nb_connector_by_cp.to_i


lcid=(0..nb_connector_by_cp).to_a
port=port0
lcp=(1..nb).map { |nocp|  
    Cp.new("ACT%03D" % [port-port0],ip,port,path,url_server,lcid).run 
    port+=1
}

trap("INT") { lcp.each { |cp| cp.shutdown } }
sleep

