##########################################################################
#  SCADA.RB :  test supervision charge point
##########################################################################

require 'Ruiby'
require_relative 'client'
require 'time'
require 'open3'
class Object
  def puts(*t) $app.instance_eval { logg("  >",*t) } end
end
Ruiby.app width: 1000, height: 600, title: "Tes supervsion bornes" do
 @borne="TOTO"
 @lconnector=%w{1 2}
   flow do
      stacki do
        @wbornes=grid
      end
      stack do
        labeli "Borne #{@borne}",{bg: "#044",fg: "#FFF"},font: "Arial bold 32"
        flowi do
          button "Reset Hard"
          button "Reset Soft"
          button "getListVersion"
          button "clearCache"
          button "getDiagnostics"
        end
        flow do
          @lconnector.each do |id|
            stack do
               table(0,0) do
                row do
                    label "etat" ; label "en prise" ; next_row
                    label "energie" ; label "12 KW" ; next_row
                    label "badge" ; label "965958979876" ; next_row
                    label "Alarme" ; label "none" ; next_row
                end
               end             
            end
            flowi do
              button "Availability:Oper"
              button "Availability:Inop"
              button "Unlock"
              button "CancelReserv"
              button "Reserve"
              button "RemoteStart"
              button "RemoteStop"
            end
          stack do 
          end
        end
      end
   end
 end
end
