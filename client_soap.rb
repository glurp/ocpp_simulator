require 'socket'
require 'timeout'

class ClientSoap
  def initialize(template,namespace,config) 
    @template=template
    @namespace=namespace
    @config=config 
  end
  def format(request,hparam) 
    buff= @template[:config][request][:req].dup
    @config.each { |k,value| buff.sub!(k,value.to_s) }
    buff.sub!(/<SOAP-ENV:Envelope\s+></,'<SOAP-ENV:Envelope '+@namespace+'><')
    buff.sub!(/(#{@config["HMESSID"]})/,"#{(Time.now.to_f*1000).round}")
    hparam.each { |k,value| buff.sub!(k,value.to_s) }
    buff.gsub!(/<wsa5:From>.*?<\/wsa5:From>/,"")    if @config["nonFrom"]
    buff
  end
  def format_http(server,request,hparam)
    data=format(request,hparam)
    action=data[/>([^<]+)<\/wsa5:Action>/,1]
    "POST #{server} HTTP/1.1\r\nAccept-Encoding: gzip,deflate\r\nContent-Type: application/soap+xml;charset=UTF-8;action=\"#{action}\"\r\n"+
         "Content-Length: #{data.size}\r\nHost: localhost:6062\r\nConnection: close\r\nUser-Agent: soap-ocpp-sim"+
         "\r\n\r\n#{data}"
         
  end
  def http_post(server,buff)
    ip=server[/http:\/\/([^:]+):(\d+)\/.*/,1]
    port=server[/http:\/\/([^:]+):(\d+)\/.*/,2]
    so=TCPSocket.new(ip,port)
    so.sync=true
    so.write(buff)
    buff.showXmlData("Soap Request:")
    head=so.gets("\r\n\r\n")
    #puts "\n\header received : " + head.gsub("\r\n"," / ")
    len= head[/Content-Length: (\d+)\r\n/,1]
    #rep=so.recv(len.to_i)
    rep=nil
    timeout(10) { rep=so.read }
    so.close rescue nil
    #puts "response : #{rep}"
    rep.showXmlData("Soap Response :")
    rep
  rescue Errno::ECONNREFUSED => e
    puts "Echec Connection => #{ip}:#{port} "
    nil
  rescue Exception => e
    puts "#{e} #{e.class} :\n   #{e.backtrace.join("\n   ")}"
    nil
  end
  def csend(server,request,hparam)
    raise("Unknown OCPP request : #{request}")  unless @template[:config][request]
    buff=format_http(server,request,hparam)
    puts buff if $DEBUG
    rep=http_post(server,buff)
    if rep
       rep.extract_data(@template[:config][request][:ret]||{})
    else
       rep
    end
  end

end
