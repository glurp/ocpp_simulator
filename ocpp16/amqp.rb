require 'bunny'

class SaiaAmqpConnector
  def initialize(host)
      @conn = Bunny.new("amqp://localhost:5672")
      @conn.start
      @channel = @conn.create_channel
      @exchange={}
      @clients=Hash.new {|h,k| h[k]=[] }
  end
  
  def post_init
   @exchange.keys.each {|topicName|
      @channel.queue("").bind(@exchange[topicName]).subscribe { |di, meta, payload|
        @clients[topicName].each {|c|  c.receive_message(topicName,payload) }
      }
   }
  end
  
  def subscribe_topic(client,topicName)
    @clients[topicName] << client
    @exchange[topicName]    = @channel.topic(topicName, :auto_delete => true)
  end
    
  def send_data(topicName,data)
    unless @exchange[topicName]
       @exchange[topicName]    = @channel.topic(topicName, :auto_delete => true)
    end
    @exchange[topicName].publish(data.to_s)
  end
  
end

if $0 == __FILE__
  ##############################################################
  #  Test amqp part
  #  Usage: > ruby amqp.rb.rb host topicsname data
  ##############################################################
  def mlog(*t)
    mess="#{Time.now.strftime('%H:%M:%S')} | #{t.join(' ')}" 
    puts mess
  end

  class ClientSimulate
    def initialize(c,amqp,top)
       @amqp=amqp
       @c=c
       @top=top
       mlog "subscribe to",top,"..."
       @amqp.subscribe_topic(self,top) 
    end
    def receive_message(top,mess)
      mlog " rec #{@c}:#{top} #{mess}"
    end
    def run()
      if @top !~ /[#\*]/
         mlog "publish to ",@top
         @amqp.send_data(@top,ARGV.join(" ")) 
      end
    end
  end
  
  ######################################################
  
  con=SaiaAmqpConnector.new(ARGV.shift)
  top=ARGV.shift
  c1=ClientSimulate.new(1,con,top)
  c2=ClientSimulate.new(2,con,top)
  c3=ClientSimulate.new(3,con,top)
  con.post_init
  c1.run()
  sleep()
end