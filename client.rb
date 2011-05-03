require 'socket'
require 'engine'

$remote_host, $remote_port, $key = '192.168.111.49', 20000, 'key'
$debug = true
connection = false
continue = true

# Try to connect to the server every 5 seconds until successful
while not connection
	begin
		@streamSock = TCPSocket.new($remote_host, $remote_port )
		connection = true
	rescue Errno::ECONNREFUSED => e
		puts "The connection was refused..."
		puts "Trying again in 5 seconds"
		sleep 5
		next
	end
end

STDOUT.puts "Connection Established" 
Thread.current.priority = -1

begin
	# Use the active session to continue to send data back and forth
	while continue
		if @send == nil or @send.alive? == false then
			#puts "inside send"
			@send = Thread.new do 
				plain_text = STDIN.gets.strip

				if plain_text == '' or plain_text == nil then
					puts "Closing Connection" if $debug
					@streamSock.close
					next
				end

				cipher_text = []
				encrypt($key, plain_text).bytes { |byte| cipher_text << byte }
				ct = cipher_text.join(':') + "\n"
				puts "Sending [#{ct.chomp}]" if $debug
				@streamSock.send(ct,0)
				puts "Sent!" if $debug
			end
		end

		if @receive == nil or @receive.alive? == false then
			@receive = Thread.new do 
				cipher_text = @streamSock.recv(1000, Socket::MSG_DONTWAIT)	# hard cap on incoming data (buffer)
				msgs = []		

				if cipher_text != nil and cipher_text != '' then
					#cipher_text = cipher_text.gsub("\n",'').split(':')
					cipher_text = cipher_text.split("\n")	#get all messages, ARRAY
					cipher_text.each { |message| msgs << message.split(':') } # 2d ARRAY					
				# this condition is reached when the user hit just the enter key instead of a msg
				elsif @streamSock.eof?
					puts "EOF Detected!"
					continue = false
					next
				# If it gets here then it's a bug
				else
					puts "User Sent #{cipher_text}, but I don't know what to do with it" if $debug
					next
				end
	
				msgs.each do |msg|
					#puts msg
					ct = msg.map { |string_byte| string_byte.to_i.chr }
					puts "#{$remote_host}: #{decrypt($key, ct.join)}"
				end

			end
		end

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
	if not @streamSock.closed? then
		puts "Closing Connection"
		@streamSock.close
	end
end

# ["MSG_EOR", "MSG_TRUNC", "MSG_OOB", "MSG_CTRUNC", "MSG_PEEK", "MSG_WAITALL", "MSG_DONTROUTE", "MSG_DONTWAIT"]
