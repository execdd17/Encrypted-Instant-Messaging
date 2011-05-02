require 'socket'
require 'engine'

if ARGV.length != 3 then
	puts "usage: #{$0} [server port] [client port] [key]"
	exit
end

$s_port, $c_port, $key = ARGV
	
def start_server(server, port)

	TCPServer.open(server, port) do |server|
		while client = server.accept
			begin
				print(client, " is accepted\n\n")
				cipher_text = client.recv(1000).chomp.split(':')
				puts "Recieved [#{cipher_text.join(':')}] ciphertext"
				if cipher_text then
					cipher_text = cipher_text.map { |string_byte| string_byte.to_i.chr }
					puts decrypt($key, cipher_text.join)
				else 
					puts "cipher_text is nil"
				end

				print(client, " is gone\n")
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
			streamSock = TCPSocket.new( "127.0.0.1", $c_port )
		rescue Errno::ECONNREFUSED => e
			puts "The connection was refused..."
			puts "Trying again in 5 seconds"
			sleep 5
			next
		end

		print "Enter Message: "
		plain_text = STDIN.gets.strip
		cipher_text = []
		encrypt($key, plain_text).bytes { |byte| cipher_text << byte }
		ct = cipher_text.join(':') + "\n"
		puts "Sending [#{ct.chomp}]"
		streamSock.send(ct,0)
		puts "Sent!"

		streamSock.close
	end
end

threads = []

threads << Thread.new { start_server('localhost', ARGV[0]) }
threads << Thread.new { start_client }

threads.each { |thread| thread.join }
