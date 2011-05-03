require 'socket'
require 'engine'

if ARGV.length != 3 then
	puts "usage: #{$0} [local host] [local port] [key]"
	exit
end

local_host, local_port, key = ARGV
debug = true


TCPServer.open(local_host, local_port) do |server|

	# Continue to accept connections even after closing one
	while client = server.accept

		begin
			puts "Connection Established" if debug
			Thread.current.priority = -1
			@continue = true
			
			# keep pushing out send and receive threads until the user enters a blank line
			# then close the connection
			while @continue
			
				# Check if a receive thread is running or exists before creating a new one
				if @receive == nil or @receive.alive? == false then
					#puts "inside receive"
					@receive = Thread.new do
						
						# hard cap on incoming data (buffer)
						# NOTE: Changing this will determine how much data can be accepted at a time
						# before the blocks get fragmented and bad things happen. For example, with a size
						# of 100,000 you can send 4000 A's in a single msg, but you wouldn't be able to do that
						# with size 1000. You would just get a decrypt error because you're trying to decrypt
						# only a subset of the entire message when you need to do it all.
						cipher_text = client.recv(5000, Socket::MSG_DONTWAIT)	
						msgs = []		
				
						if cipher_text != nil and cipher_text != '' then
							cipher_text = cipher_text.split("\n")	#get all messages, ARRAY
							cipher_text.each { |message| msgs << message.split(':') } # 2d ARRAY	

						# this condition is reached when the user hit just the enter key instead of a msg
						elsif client.eof?
							puts "EOF Detected!"
							@continue = false
							next
						else
							puts "User Sent #{cipher_text}, but I don't know what to do with it" if debug
							next
						end

						msgs.each do |msg|
							#puts msg
							ct = msg.map { |string_byte| string_byte.to_i.chr }

							begin
								#puts "#{client.addr[-1]}: #{decrypt(key, ct.join)}"
								plain_text = decrypt(key, ct.join)

								#check hmac
								plain_text = plain_text.chars.to_a
								#puts "Plain_text is #{plain_text}"

								hmac_start = plain_text.length-64
								hmac_end = plain_text.length-1

								#puts "Length of MSG #{plain_text.length}"
								#puts "START: #{plain_text[hmac_start].hex}"
								#puts "END: #{plain_text[hmac_end].hex}"
								
								recv_hmac = plain_text.slice(hmac_start..hmac_end)
								plain_text = plain_text.slice(0..(hmac_start-1))

								#puts "HMAC length is #{recv_hmac.length}"
								#puts "Receieved Message #{plain_text.join(':')}"

								hmac = OpenSSL::HMAC.digest('SHA512', key, plain_text.join)
								#puts "local: #{hmac}", hmac.length
								#puts "given: #{recv_hmac.join}", recv_hmac.length

								if hmac == recv_hmac.join then
									puts "HMAC Match" if debug
									puts "#{client.addr[-1]}: #{plain_text.join}"
								else
									raise OpenSSL::HMACError, "HMACs do not match!"
								end

							# Can be the result of using different keys on each end, or too small a recv
							# buffer
							rescue OpenSSL::Cipher::CipherError => e
								puts "An Error Occurred While Decrypting.."
								puts e.message if debug
								puts e.backtrace.inspect if debug
							end
						end

					end
				end

				# Check if a send thread is running or exists before creating a new one
				if @send == nil or @send.alive? == false then
					#puts "inside send"
					@send = Thread.new do 
						plain_text = STDIN.gets.strip

						# stop processing for this session and close connection 
						if plain_text == '' or plain_text == nil then
							@continue = false
							break
						end

						## hmac creation; 64 bytes appended to plain_text msg
						hmac = OpenSSL::HMAC.digest('SHA512', key, plain_text)
						full_msg = plain_text + hmac

						cipher_text = []
						encrypt(key, full_msg).bytes { |byte| cipher_text << byte }
						ct = cipher_text.join(':') + "\n"
						puts "Sending [#{ct.chomp}]" if debug
						client.send(ct,0)
						puts "Sent!" if debug
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
			puts "Closing Connection" if debug
			client.close if not client.closed?
		end
	end
end

