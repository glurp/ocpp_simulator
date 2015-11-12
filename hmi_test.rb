require 'Ruiby'
require_relative 'client'
require 'time'
require 'open3'
class Object
  def puts(*t) $app.instance_eval { logg("  >",*t) } end
end
Ruiby.app width: 800, height: 400, title: "Test config borne" do
  $app=self
  @lastTransactionId=nil
	stack do
		stacki do
      ctx=make_StockDynObject("ee",{"cp" => "TEST1" , "cs" => "http://ns308363.ovh.net:6060/ocpp" ,"con"=>"1","nonfrom"=>"0"})
      ctx.nonfrom.value= (ctx.nonfrom.value && ctx.nonfrom.value=="1")
			table(0,0) { 
        row {
          cell_right(label "ChargeboxId : ")
          @cp=cell_hspan(3,box { flow {
              @cp=entry(ctx.cp,10,{font: 'Courier 10'})
              label("Connecteur :") ; combo(%w{C01 C02 C03 C04},ctx.con.value.to_i) {|text,index| ctx.con.value=index+1}
            }})
        next_row
          cell_right(label "")
          cell_hspan(3,check_button("pas de champ from",DynVar.stock("non from",ctx.nonfrom)))
         next_row          
          cell_right(label "Server : ")
          @srv=cell_hspan(3,entry(ctx.cs,10,{font: 'Courier 10'}))
        next_row
          cell(button("Cdg",bg: "#FFAABB")    { ocpp_send(ctx,:hbeat)     })
          cell(button("Authorize",bg: "#AABBFF")         { ocpp_send(ctx,:authorize) })
			    cell(button("MeterValues",bg: "#AA88AA")       { ocpp_send(ctx,:meterValue)})
			    cell(button("StatusNotif.",bg: "#AAAAAA"){ ocpp_send(ctx,:statusNotification)})
        next_row
			    cell(button("Start Tr.") { ocpp_send(ctx,:startTransaction) })
          cell(button("Stop Tr.")  { ocpp_send(ctx,:stopTransaction)  })
          cell(button("Ok ?")  {
                Open3.popen3("C:/Program Files (x86)/PuTTY/plink.exe",
                  "-load","tiles","lcharge0") { |fin,fout,ferr| 
                    logg fout.read 
                }
          })
          cell(button("lcharge?")  {
                Thread.new {Open3.popen3("C:/Program Files (x86)/PuTTY/plink.exe",
                  "-load","tiles","lcharge") { |fin,fout,ferr|
                    a= fout.read
                    gui_invoke { logg a}
                }}
                sleep 3
              }
          )
        }
      }
		end
		@log=text_area(100,100,{font: 'Courier 8', bg: "#FFF", fg: "#000"})
    flowi { button("Clear log") { @log.text=""} ; buttoni("Exit") { exit(0) } } 
	end
  def logg(*t) @log.append  t.join(" ")+"\n" end
  def ocpp_send(ctx,request,params={})
    logg("<<<<<#{request} from #{ctx.cp.value} ==>  #{ctx.cs.value}")
    unless $cp_to_cs[:config][request]
      logg "request #{request} unknown !"
      logg"Should be one of #{$cp_to_cs[:config].keys.map(&:to_s).join(", ")}"
    end
    conf={"HCHARGEBOXID"=>ctx.cp.value, 
         "HMESSID"=>"A%", "HFROM"=>"http://localhost:9090/ocpp", 
         "HTO"=>"http://you.com"
    }
    conf["nonFrom"]=true if ctx.nonfrom
    r=PostSoap.new(conf)
     h=$cp_to_cs[:config][request]
     param= h[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
     param= param.nearest_merge( default_params(request).merge({"CONID"=>ctx.con.value.to_s}) )     
     ret=r.csend(ctx.cs.value,request,param) 
     @lastTransactionId=ret["TRANSACID"] if ret
     logg ret.inspect
     logg "."
  end
  
  def nowRfc() Time.now.utc.round.iso8601(3) end
  def default_params(request)
    { 
      hbeat:                 {},
      statusNotification:    {"STATUS"=>"Occupied","ERRORCODE" => "NoError","TIMESTAMP" => nowRfc()},
      authorize:             {"TAGID"=> "12345678"},
      startTransaction:      {"TAGID"=> "12345678","TIMESTAMP"=> nowRfc() ,"METERSTART"=> 0},
      stopTransaction:       {"TRANSACTIONID"=>@lastTransactionId||"101",
                              "TAGID"=> "12345678","TIMESTAMP"=> nowRfc(),"METERSTOP"=> 100},
      meterValue:            {"VALUE"=>Time.now.to_i % 1000, 
         "TRANSACTID" => (1.to_i+rand(100000)*100).to_s, "TIMESTAMP" => nowRfc()},
    }[request]
  end
end

=begin

  
  def send_authorize() charge.csend(:authorize,{"CONID"=> conid,"TAG"=> "12345678" }) end
  
=end