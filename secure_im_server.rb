require 'socket'
require 'engine'

if ARGV.length != 5 then
	puts "usage: #{$0} [local host] [local port] [remote host] [remote port] [key]"
	exit
end

$local_host, $local_port, $remote_host, $remote_port, $key = ARGV
$debug = true

def start_server(server, port)

	TCPServer.open(server, port) do |server|
		while client = server.accept
			begin
				puts "Inbound Connection Established" if $debug
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
				puts "#{$remote_host}: #{decrypt($key, cipher_text.join)}"
			rescue Exception => e
				puts e.message
				puts e.backtrace.inspect
			ensure
				client.close
				puts "Inbound Connection Terminated" if $debug
			end
		end
	end
end

def start_client
	loop do

		begin 
			streamSock = TCPSocket.new( $remote_host, $remote_port )
		rescue Errno::ECONNREFUSED => e
			puts "The connection was refused..."
			puts "Trying again in 5 seconds"
			sleep 5
			next
		end

		STDOUT.puts "Outbound Connection Established" if $debug
		plain_text = STDIN.gets.strip

		if plain_text == '' or plain_text == nil then
			streamSock.close
			puts "Outbound Connection Terminated" if $debug
			next
		end
		
		cipher_text = []
		encrypt($key, plain_text).bytes { |byte| cipher_text << byte }
		ct = cipher_text.join(':') + "\n"
		puts "Sending [#{ct.chomp}]" if $debug
		streamSock.send(ct,0)
		puts "Sent!" if $debug

		streamSock.close
		puts "Outbound Connection Terminated" if $debug
	end
end

##### Main #####
threads = []
threads << Thread.new { start_server($local_host, $local_port) }
threads << Thread.new { start_client }
threads.each { |thread| thread.join }
