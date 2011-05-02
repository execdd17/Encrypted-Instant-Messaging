require 'socket'
require 'engine'

$remote_host, $remote_port, $key = 'localhost', 20000, 'key'
$debug = true
connection = false

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

STDOUT.puts "Connection Established" if $debug   
Thread.current.priority = -1

begin 
	loop do
		if @send == nil or @send.alive? == false then
			puts "inside send"
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
			puts "inside receive"
			@receive = Thread.new do 
				cipher_text = @streamSock.recv(1000)	# hard cap on incoming data (buffer)
			
				if cipher_text != nil and cipher_text != '' then
					cipher_text = cipher_text.chomp.split(':')

				# this condition is reached when the user hit just the enter key instead of a msg
				else
					puts "User Sent Empty String" if $debug
					next
				end

				puts "Recieved [#{cipher_text.join(':')}] ciphertext" if $debug
		
				cipher_text = cipher_text.map { |string_byte| string_byte.to_i.chr }
				puts "#{$remote_host}: #{decrypt($key, cipher_text.join)}"
			end
		end

		while (@send == nil or @send.alive?) and (@receieve == nil or @receive.alive?)
			#puts "Inside Loop. #{@send} #{@receive}"
			sleep 1
		end
	end
ensure
	puts "Closing Connection" if $debug
	@streamSock.close if not @streamSock.closed?
end
