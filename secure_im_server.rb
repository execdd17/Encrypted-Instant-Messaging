require 'socket'
require 'engine'

if ARGV.length != 5 then
	puts "usage: #{$0} [local host] [local port] [remote host] [remote port] [key]"
	exit
end

$local_host, $local_port, $remote_host, $remote_port, $key = ARGV
$debug = false

def start_server(server, port)

	TCPServer.open(server, port) do |server|
		while client = server.accept
			begin
				#print(client, " is accepted\n\n") if $debug
				puts "Inbound Connection Established"
				cipher_text = client.recv(1000).chomp.split(':')
				puts "Recieved [#{cipher_text.join(':')}] ciphertext" if $debug
				if cipher_text then
					cipher_text = cipher_text.map { |string_byte| string_byte.to_i.chr }
					puts decrypt($key, cipher_text.join)
				else 
					puts "cipher_text is nil"
				end

				puts "Inbound Connection Terminated"
			rescue Exception => e
				puts e.message
				puts e.backtrace.inspect
			ensure
				client.close
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

		STDOUT.puts "Outbound Connection Established"
		plain_text = STDIN.gets.strip
		cipher_text = []
		encrypt($key, plain_text).bytes { |byte| cipher_text << byte }
		ct = cipher_text.join(':') + "\n"
		puts "Sending [#{ct.chomp}]" if $debug
		streamSock.send(ct,0)
		puts "Sent!" if $debug

		streamSock.close
		puts "Outbound Connection Terminated"
	end
end

##### Main #####
threads = []
threads << Thread.new { start_server($local_host, $local_port) }
threads << Thread.new { start_client }
threads.each { |thread| thread.join }
