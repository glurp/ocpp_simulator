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
    > ruby parc._simrb  nb ip        port0 path    url_server                  nb_connector_by_cp
    > ruby parc_sim.rb  10 localhost 6060  /ocpp   http://localhost:9090/ocpp  2
  "
  exit!(1)  
end

nb,ip,port0,path,url_server,nb_connector_by_cp = *ARGV
nb=nb.to_i
port0=port0.to_i
nb_connector_by_cp=nb_connector_by_cp.to_i


lcid=(1..nb_connector_by_cp).to_a
lcp=(1..nb).map { |nocp|  
    Cp.new("ACT%03d" % nocp,ip,port0+nocp-1,path,url_server,lcid).run 
}

trap("INT") { lcp.each { |cp| cp.shutdown } ; exit!(0)}
sleep

