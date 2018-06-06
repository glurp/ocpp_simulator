#!/usr/bin/ruby


# gem install websocket-client-simple 

#############################################################
#   ocpp_rooter.rb : client OCPP-J 1.6  rooting 
#       request to other CS
#############################################################


class OcppJRooter
  class << self
    URL=ARGV.size>1 ? ARGV[1] : nil
    def connect(cbi)
        @hCbiClient||={}
        p  @hCbiClient
        unless @hCbiClient[cbi]
          $app.log("@hCbiClient => #{@hCbiClient}")
          $app.log("Create ROOT ws for cbi #{cbi}...")
          @hCbiClient[cbi]=ClientOccpJ.new(URL,cbi) 
        end
        @hCbiClient[cbi]
    end
    def close(cbi)
        @hCbiClient[cbi].close() if @hCbiClient[cbi]
    end
    def asyncRooter(cbi,name,message)
       return close(cbi) if message.nil?   # internal message "closed"
       connect(cbi).aRoot(name,message) 
    end
    def syncRooter(cbi,name,message,defaultReponse,&b)
       con=connect(cbi)
       if con.connected? && message
         con.syncRoot(name,message,b) rescue yield(defaultReponse)
       else
         yield(defaultReponse)
       end
    end  
  end
end

class ClientOccpJ
  def initialize(url,cbi)
    @url=url
    @cbi=cbi
    @ws=nil
    @connected=false
    @id=0
    connect()
  end
  def connected?() @connected end
  def close()
     ($app.log("ROOT: close for #{@cbi}") ; @ws.close() ; sleep(0.5) ) if @connected && @ws
  end
  def connect(&block)
    wsurl="#{@url}/#{@cbi}"
    $app.log("ROOT: connection to #{wsurl} ...")
    ici=self
    WebSocket::Client::Simple.connect(wsurl) do |ws|
      ws.on :open do 
        ici.instance_eval {
          $app.log("ROOT: connection to #{wsurl} success !")
          p self
          @ws=ws
          @id=0
          @connected=true
          block.call if block
        }
      end
      ws.on :message do |msg| 
        ici.instance_eval {
          data = JSON.parse(msg.data)
          if @data.size>=3 && @data[0]==2
             doRequest(data)
          else 
             if @responseBloc
                @responseBloc,respb=nil,@responseBloc
                respb.call(data) 
             end
          end
        }
      end
      ws.on :close do |e| 
        ici.instance_eval {
          @connected=false
          @ws=nil
          $app.log("ROOT: closed #{@cbi}")
        }
      end
      ws.on :error do |e| $app.log("ROOT: Error on  link #{wsurl} : #{e}") end
    end
    sleep(0.5)
    $app.log(".")
  end
  
  def aRoot(name,message)
    $app.log("     #{@cbi} try to aroot #{name}:#{message}...")
    unless @connected    
      connect { root(name,message) }
      return
    end
    id,@id=@id,@id+1
    m=JSON.generate([2,id,name,message])
    @ws.send(m) rescue $app.log("  ROOT error send #{$!}")
  end
  def syncRoot(name,message,&b)
    $app.log("     #{@cbi} try to syncroot #{name}:#{message}...")
    unless @connected    
      connect { syncRoot(name,message,b) }
      return
    end
    id,@id=@id,@id+1
    m=JSON.generate([2,id,name,message])
    @responseBloc=b
    @ws.send(m) rescue $app.log("  ROOT error send #{$!}")
  end

  def doRequest(message)
     $app.do_request(@cbi,message) do |response|
       if @connected  && @ws
         if response 
            @ws.send(JSON.generate([3,message[1],reponse]))
         else
            @ws.send(JSON.generate([4,message[1],"error rounting OCPP"]))
         end
       end
     end
  end
end



