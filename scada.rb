##########################################################################
#  SCADA.RB :  test supervision charge point
##########################################################################

require 'Ruiby'
require_relative 'client'
require 'time'
require 'open3'

$BG="#003030"

class Object
  def puts(*t) $app.instance_eval { logg("  >",*t) } end
end

Ruiby.app width: 600, height: 300, title: "Tes supervsion bornes" do
 @borne="TOTO"
 @lconnector=%w{1 2}
 stack do
 notebook do
 page("Parc") do
  stack do end
 end
 page("Bornes") do 
   separator
   flow do
      stacki do
        @wbornes=grid(%w{name id state},130)
        @wbornes.set_data([%w{TOTO 01},%w{TITI 02}])
        buttoni "Exit" do exit(0) end
      end
      
      stack do
        labeli "Borne #{@borne}",{name: "title"}
        flowi do
          button "Reset Hard"
          button "Reset Soft"
          button "getListVersion"
          button "clearCache"
          button "getDiagnostics"
        end
        space
        separator
        space
        flow do
          @lconnector.each do |id|
            separator
            stack do
             labeli "Connector #{id}",{name: "title"}
             flowi { table(0,0) do
              row do
                  cell_right(label "etat :")       ; cell_left(label "en prise")     ; next_row
                  cell_right(label "energie max:")    ; cell_left(label "12 KW")        ; next_row
                  cell_right(label "energie delovré:") ; cell_left(label "0 KW")        ; next_row
                  cell_right(label "badge :")      ; cell_left(label "965958979876") ; next_row
                  cell_right(label "Alarme :")     ; cell_left(label "none")         ; next_row
              end
             end }
             stack {}
             stacki do
               flow do
                regular
                button "Availability:Oper"
                button "Availability:Inop"
                button "Reserve"
               end
               flow do
                button "CancelReserv"
                button "UpdateFirmware"
               end
               flow do
                regular
                button "Unlock"
                button "RemoteStart"
                button "RemoteStop"
               end
             end
          end             
        end
     end
   end
 end
 end
 end
 end
  def_style <<EEND
.button { 
  background-image: none;
  font: Sans bold 12px;
  color: #A99;
  border-radius: 8px;
  padding: 3px 7px 2px 5px;
  border-width: 3px;
  -GtkButton-shadow-type:none;
  -GtkWidget-focus-line-width: 4;
}
GtkSeparator {   padding: 20px 0px 10px 0px;}
GtkLabel {  font: Sans  10px;}
GtkLabel #title  {   background: #044; font: Sans  14px;}
GtkEntry {   font: Sans bold 10px;}
GtkGrid { font: Sans bold 10px;}
GtkProgressBar { 
 background-image: -gtk-gradient (linear,left bottom, right top, from(#EEF), to(#00F));
}

EEND
end
