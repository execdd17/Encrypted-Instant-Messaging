require 'socket'
require 'engine'

#if ARGV.length != 5 then
#	puts "usage: #{$0} [local host] [local port] [remote host] [remote port] [key]"
#	exit
#end

$local_host, $local_port, $key = 'localhost', 20000, 'key'
$debug = true


TCPServer.open($local_host, $local_port) do |server|
	while client = server.accept
		begin
			puts "Connection Established" if $debug
			Thread.current.priority = -1
			
			if @receive == nil or @receive.alive? == false then
				puts "inside receive"
				receive = Thread.new do
					cipher_text = client.recv(1000)	# hard cap on incoming data (buffer)
			
					if cipher_text != nil and cipher_text != '' then
						cipher_text = cipher_text.chomp.split(':')

					# this condition is reached when the user hit just the enter key instead of a msg
					else
						puts "User Sent Empty String" if $debug
						next
					end

					puts "Recieved [#{cipher_text.join(':')}] ciphertext" if $debug
			
					cipher_text = cipher_text.map { |string_byte| string_byte.to_i.chr }
					puts "#{client.addr[-1]}: #{decrypt($key, cipher_text.join)}"
				end
			end

			if @send == nil or @send.alive? == false then
				puts "inside send"
				send = Thread.new do 
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
			
			puts "Going into while.."

			while (@send == nil or @send.alive?) and (@receieve == nil or @receive.alive?)
				puts "Inside Loop. #{@send} #{@receive}"
				sleep 1
			end

			puts "Made it out"
	
		rescue Exception => e
			puts e.message
			puts e.backtrace.inspect
		ensure
			puts "Closing Connection" if $debug
			client.close if not client.closed?
		end
	end
end

