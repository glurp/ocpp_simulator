######################################################################################
#    tc_batch.rb : 
######################################################################################

require_relative 'tc.rb'

def csend(url,cmd,args)
  puts "#{'='*20} #{cmd}..."
  estart=Time.now
  puts $r.csend(url,cmd,args)
  eend=Time.now
  puts "#{(eend.to_f-estart.to_f)*1000} ms \n\n\n"
  sleep 8
end

$cbi="gir.vat.mx.029ea7"
$server="http://5.39.17.98:6160/ocpp"  

$hfrom ="http://localhost:9090/ocpp"
$hto   =$server

puts "Requests: #{$client_cs_to_cp[:config].keys.join(", ")}"

$r=PostSoapCp.new({ 
     "HCHARGEBOXID"=> $cbi,
     "HMESSID"     => "A%", 
     "HFROM"       => $hfrom,
     "HTO"         => $hto
})


#ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  reset TYPE Hard
#ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  clearCache
#ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  changeAvailability CONID 1 TYPE Operative
#ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  remoteStartTransaction CONID 1 TAGID 112233
#ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  remoteStopTransaction TANSCTIONID 1111
#ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  unlockConnector  CONID 1

#csend($server,"reset",{"TYPE" => "Soft"})
#csend($server,"reset",{"TYPE" => "Hard"}) 

csend($server,:clearCache,{}) 
loop {
   csend($server,:changeAvailability,{"CONID" => "1" , "TYPE" => "Inoperative"}) 
   csend($server,:changeAvailability,{"CONID" => "1" , "TYPE" => "Operative"}) 

   csend($server,:remoteStartTransaction,{"CONID" => "1", "TAGID" => "112233"}) 
   sleep 10
   csend($server,:remoteStopTransaction ,{ "TRANSACID" => "1111"}) 

   puts "sleeping 30 s"
   sleep 30
}
#csend($server,:unlockConnector,{"CONID" => "1"}) 

