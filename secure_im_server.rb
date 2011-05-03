require 'socket'
require 'engine'

#if ARGV.length != 5 then
#	puts "usage: #{$0} [local host] [local port] [remote host] [remote port] [key]"
#	exit
#end

$local_host, $local_port, $key = '192.168.111.49', 20000, 'key'
$debug = true


TCPServer.open($local_host, $local_port) do |server|

	# Continue to accept connections even after closing one
	while client = server.accept

		begin
			puts "Connection Established" if $debug
			Thread.current.priority = -1
			@continue = true
			
			# keep pushing out send and receive threads until the user enters a blank line
			# then close the connection
			while @continue
			
				# Check if a receive thread is running or exists before creating a new one
				if @receive == nil or @receive.alive? == false then
					#puts "inside receive"
					@receive = Thread.new do
						cipher_text = client.recv(1000, Socket::MSG_DONTWAIT)	# hard cap on incoming data (buffer)
						msgs = []		
				
						if cipher_text != nil and cipher_text != '' then
							#cipher_text = cipher_text.gsub("\n",'').split(':')
							cipher_text = cipher_text.split("\n")	#get all messages, ARRAY
							cipher_text.each { |message| msgs << message.split(':') } # 2d ARRAY	
							#cipher_text = cipher_text.chomp.split(':')

						# this condition is reached when the user hit just the enter key instead of a msg
						elsif client.eof?
							puts "EOF Detected!"
							@continue = false
							next
						else
							puts "User Sent #{cipher_text}, but I don't know what to do with it" if $debug
							next
						end

						msgs.each do |msg|
							#puts msg
							ct = msg.map { |string_byte| string_byte.to_i.chr }
							puts "#{client.addr[-1]}: #{decrypt($key, ct.join)}"
						end

						#puts "Recieved [#{cipher_text.join(':')}] ciphertext" if $debug
		
						#cipher_text = cipher_text.map { |string_byte| string_byte.to_i.chr }
						#puts "#{client.addr[-1]}: #{decrypt($key, cipher_text.join)}"
					end
				end

				# Check if a send thread is running or exists before creating a new one
				if @send == nil or @send.alive? == false then
					#puts "inside send"
					@send = Thread.new do 
						plain_text = STDIN.gets.strip

						if plain_text == '' or plain_text == nil then
							puts "Closing Connection" if $debug
							client.close
							next
						end

						cipher_text = []
						encrypt($key, plain_text).bytes { |byte| cipher_text << byte }
						ct = cipher_text.join(':') + "\n"
						puts "Sending [#{ct.chomp}]" if $debug
						client.send(ct,0)
						puts "Sent!" if $debug
					end
				end

				# busy loop until either a send or receive thread finishes
				# NOTE: Wait/Notify would be more efficient
				while @send.alive? and @receive.alive?
					#puts "Inside Loop. #{@send} #{@receive}"
					sleep 1
				end
			end
		rescue Exception => e
			puts e.message
			puts e.backtrace.inspect
			exit
		ensure
			puts "Closing Connection" if $debug
			client.close if not client.closed?
		end
	end
end

