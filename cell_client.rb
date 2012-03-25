require 'socket'
require 'celluloid'
require './engine'

class Client
  include Celluloid

  # Try to connect to the server every 5 seconds until successful      
  def initialize(remote_host, remote_port, key, debug=true)
      @remote_host, @remote_port, @key = remote_host, remote_port, key
      @debug = debug
  end

  def connect
    begin                                                              
      until @streamSock = TCPSocket.new(@remote_host, @remote_port); end           
    rescue Errno::ECONNREFUSED => e                                    
      puts "The connection was refused..."                             
      puts "Trying again in 5 seconds"                                 
      sleep 5                                                          
    end                                                                
  end                                                                  

  def connected?
    not @streamSock.closed?
  end

  def write_to_sock
    plain_text = STDIN.gets.strip                                 
    
    if plain_text == '' or plain_text == nil then                 
      puts "Closing Connection and Exiting Program.."             
      @streamSock.close                                           
      exit                                                        
    end                                                           
    
    ## hmac creation; 64 bytes appended to plain_text msg         
    hmac      = OpenSSL::HMAC.digest('SHA512', @key, plain_text)        
    full_msg  = plain_text + hmac                                  
    
    cipher_text = []                                              
    encrypt(@key, full_msg).bytes { |byte| cipher_text << byte }   
    ct = cipher_text.join(':') + "\n"                             
    
    puts "Sending [#{ct.chomp}]" if @debug                         
    @streamSock.send(ct,0)                                        
    puts "Sent!" if @debug                                         
  end

  def read_from_sock
    
    # hard cap on incoming data (buffer)                                    
    puts "Waiting for data..."                                              
    cipher_text = @streamSock.recv(5000)                                    
    puts "Data received"                                                    
    msgs = []                                                               
                                                                            
    if cipher_text and cipher_text != '' then                               
      cipher_text = cipher_text.split("\n") #get all messages, ARRAY        
      cipher_text.each { |message| msgs << message.split(':') } # 2d ARRAY          
    # this condition is reached when the user hit just the enter key instead of a msg
    elsif @streamSock.eof?                                                  
      puts "EOF Detected!"                                                  
      continue = false                                                      
    # If it gets here then it's a bug                                       
    else                                                                    
      puts "User Sent #{cipher_text}, but I don't know what to do with it" if @debug
    end                                                                     
                                                                            
    msgs.each do |msg|                                                      
      ct = msg.map { |string_byte| string_byte.to_i.chr }                   
                                                                            
      begin                                                                 
        plain_text = decrypt(@key, ct.join)                                  
                                                                            
        #check hmac                                                         
        plain_text = plain_text.chars.to_a                                  
                                                                            
        hmac_start = plain_text.length-64                                   
        hmac_end = plain_text.length-1                                      
                                                                            
        recv_hmac = plain_text.slice(hmac_start..hmac_end)                  
        plain_text = plain_text.slice(0..(hmac_start-1))                    
                                                                            
        hmac = OpenSSL::HMAC.digest('SHA512', @key, plain_text.join)         
                                                                            
        if hmac == recv_hmac.join then
          puts "HMAC Match" if @debug                                        
          puts "#{@remote_host}: #{plain_text.join}"                         
        else                                                                
          raise OpenSSL::HMACError, "HMACs do not match!"                   
        end                                                                 
        
      # either the buffer wasn't large enough to transfer the entire msg at once,
      # or the keys don't match from client/server                          
      rescue OpenSSL::Cipher::CipherError => e
        puts "An Error Occurred While Decrypting.." 
        puts e.message if @debug
        puts e.backtrace.inspect if @debug                                   
      end                                                                   
    end                                                                         
  end
end

c  = Client.new(*ARGV)
c.connect
c.read_from_sock!
c.write_to_sock!
