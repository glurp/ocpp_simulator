require 'Ruiby'
require_relative 'client'
require_relative 'server'
require 'time'
require 'open3'

class Object
  def puts(*t) $app.instance_eval { logg("  >",*t) } end
end

module Ruiby_dsl
  def logg(*t) 
    to= t.join(" ").encode("UTF-8",'binary', invalid: :replace, undef: :replace, replace: '?')
    $stdout.puts t.join(" "); 
    @log.append  t.join(" ")+"\n" end
end

##################### Server Ocpp ###################

class Application 
  include AppliAbstract
  def initialize(port)
    server="http://0.0.0.0:#{port}/ocpp"
    @port=port
    @s=ServerSoapOcpp.new(self,{:ip=> "0.0.0.0" , :port=> port})
    @s.start
  end
  def remoteStartTransaction(hpara)   {"TRANSID"=> Time.now.to_i} end
  def remoteStopTransaction(hpara)   {} end
  def reserveNow(hpara) 
      puts "DDE Reservation, parametres= #{hpara.inspect}"
      rep=$reservation_next_accept ? "Accepted" : "Rejected"
      puts "DDE Reservation response => #{rep}"
      {"STATUS" => rep}
  end
  def cancelReservation(hpara)        {} end
  
  def stop() @s.shutdown() ; puts "Ocpp Server is killed!!"end
  def wait() @s.join end
end

module Ruiby_dsl
  def reinit_serveur(url)
    if defined?(@appOcpp) && @appOcpp!=nil
      @appOcpp.stop
    end
    @portServeur=url.scan(/:\d\d+/).first[1..-1].to_i
    @appOcpp=::Application.new(@portServeur)
  end
end

################## client OCPP => scada ##############################
$tagid="123456"
module Ruiby_dsl
  def mess(request)
    ocpp_send(@ctx,request)
  end
  def ocpp_send(ctx,request,params={})
    logg("<<<<<#{request} from #{ctx.cp.value} ==>  #{ctx.cs.value}")
    $tagid= ctx.tag.value
    unless $cp_to_cs[:config][request]
      logg "request #{request} unknown !"
      logg"Should be one of #{$cp_to_cs[:config].keys.map(&:to_s).join(", ")}"
    end
    conf={"HCHARGEBOXID"=>ctx.cp.value, 
         "HMESSID"=>"A%", 
         "HFROM"=>@ctx.url.value, 
         "HTO"=> @ctx.cs.value
    }
    conf["nonFrom"]=true if ctx.nonfrom
    r=PostSoapCs.new(conf)
    h=$cp_to_cs[:config][request]
    
    p "===================================="
    param= h[:params].inject({}) { |h,k| h[k] = rand(100000).to_s ; h}
    param= param.merge( default_params(request).merge({"CONID"=>ctx.con.value.to_s}) )     
    param=param.merge(params)
    (panel("Editions des parametres") { properties("",param,:edit=>true)  }) if param.size>0 && ctx.saisie.value=="1"
    p "===================================="

    Thread.new {
      ret=r.csend(ctx.cs.value,request,param) 
      gui_invoke { 
        @lastTransactionId=ret["TRANSACID"] if ret
        logg ret.inspect
        logg "."
      }
    }
  end
  def nowRfc() Time.now.utc.round.iso8601(3) end
  def default_params(request)
    { 
      hbeat:                 {},
      dataTransfert:         {"VENDORID" => "Actemium", "MESSID" => Time.now.to_i.to_s, "DATA" => ""},
      bootNotification:      {"VENDOR"=> "Actemium", "MODEL"=> "A1","CPSN"=> "0","CBSN"=> "","VERSION"=>"0.0.1",
                            "ICCID"=> "0000","IMSI" => "0000", "METERTYPE" =>"KW", "METERSN"=>""
                },
      statusNotification:    {"STATUS"=>"Available","ERRORCODE" => "NoError","VENDORERROR_CODE" => "", "TIMESTAMP" => nowRfc()},
      authorize:             {"IDTAG"=> $tagid},
      startTransaction:      {"TAGID"=> $tagid,"TIMESTAMP"=> nowRfc() ,"METERSTART"=> 0},
      stopTransaction:       {"TRANSACTIONID"=>@lastTransactionId||"101",
                              "TAGID"=> $tagid,"TIMESTAMP"=> nowRfc(),"METERSTOP"=> 100},
      meterValue:            {"VALUE"=>Time.now.to_i % 1000, 
         "TRANSACTID" => (@lastTransactionId).to_s, "TIMESTAMP" => nowRfc()},
    }[request]
  end
end

################################## Main window ##############################
$reservation_next_accept=true

Ruiby.app width: 800, height: 400, title: "Test config borne" do
  $app=self
  @lastTransactionId=nil
  ctx=make_StockDynObject("ee",{"tag"=> "1234567", "cp" => "TEST1" , "cs" => "http://ns308363.ovh.net:6060/ocpp" ,"con"=>"1","nonfrom"=>"0","isPeriode"=>false, "periode"=>10, "url" => "http://localhost:6161","saisie" => false})
  @ctx=ctx
  after(0) { reinit_serveur(@ctx.url.value) }
	stack do
		stacki do
      ctx.nonfrom.value= (ctx.nonfrom.value && ctx.nonfrom.value=="1")
			table(0,0) { 
        row {
          cell_right(label "ChargeboxId : ")
          @cp=cell_hspan(3,box { flow {
              @cp=entry(ctx.cp,10,{font: 'Courier 10'})
              label("Connecteur :")
              combo(%w{C01 C02 C03 C04},ctx.con.value.to_i) {|text,index| 
                 ctx.con.value=index+1
              }
            }})
        next_row
          cell_right(label "tagId : ")
          @srv=cell_hspan(3,entry(ctx.tag,20,{font: 'Courier 10'}))
        next_row
          cell_right(label "")
          cell_hspan(1,check_button("Editions des requettes",ctx.saisie))
        next_row
          cell_right(label "")
          cell_hspan(1,check_button("pas de champ from",ctx.nonfrom))
          cell_hspan(2,box do
            frame("Cyclique") do
              flow do 
                check_button("emission periodique",ctx.isPeriode)
                separator
                label("periode (ms) :");entry(ctx.periode,5)
              end
            end
          end)
         next_row          
          cell_right(label "Supervision : ")
          @srv=cell_hspan(3,entry(ctx.cs,10,{font: 'Courier 10'}))
         next_row          
          cell_right(label "Serveur OCPP : ")
          cell_hspan(2,@ocpp=entry(ctx.url,10,{font: 'Courier 10'}))
          cell(button("Change") {
            reinit_serveur(@ocpp.text)
          })
        next_row
          cell(button("Cdg",bg: "#FFAABB")    { ocpp_send(ctx,:hbeat)     })
          cell(button("dataTransfert",bg: "#00FF00")    { ocpp_send(ctx,:dataTransfert,{"DATA"=> "","VENDORID"=>"Regis"})     })
          cell(button("Authorize",bg: "#AABBFF")         { ocpp_send(ctx,:authorize) })
			    cell(button("MeterValues",bg: "#AA88AA")       { ocpp_send(ctx,:meterValue)})
			    cell(button("StatusNot.",bg: "#AAAAAA") { 
             rep= ask("en prise?") ? "Occupied" : "Available"
             code=promptSync("Error vendor code ?") 
             error =  (code.size>0) ? "OtherError" : "NoError"
             ocpp_send(ctx,:statusNotification,{"STATUS" => rep,"ERRORCODE" => error,"VENDORERROR_CODE" => code||""})
          })
        next_row
			    cell(button("Start") { ocpp_send(ctx,:startTransaction) })
          cell(button("Stop")  { ocpp_send(ctx,:stopTransaction)  })
			    cell(button("AcceptR?",bg: "#AABBFF") { 
              ok=ask("Accepter la prochaine reservation ?")
              puts "Accepter prochaine reservation ? =>  #{ok}"
              $reservation_next_accept= ok
          })
          cell(button("Boot")  { ocpp_send(ctx,:bootNotification)  })
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
  
  #------------- Executions automatiques
  @top=0
  @ctx.isPeriode.value=false
  anim(100) do
    @top+=1
    #log [@top,@ctx.isPeriode.value,@ctx.periode.value.to_i].inspect
    if @ctx.isPeriode.value
       if (@top % (@ctx.periode.value.to_i/100))==0
          logg "sending..."
          ocpp_send(@ctx,:dataTransfert,{}) 
          @log.text=""
       end
    end
  end
end

=begin

  
  def send_authorize() charge.csend(:authorize,{"CONID"=> conid,"TAG"=> "12345678" }) end
  
=end