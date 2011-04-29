require 'socket'
require 'engine'

if ARGV.length != 1 then
	puts "usage: #{$0} [key]"
	exit
end
	
def start(server, port)
	key = ARGV[0]

	TCPServer.open(server, port) do |server|
		while client = server.accept
			begin
				print(client, " is accepted\n\n")
				cipher_text = client.gets.chomp.split(':')
				puts "Recieved [#{cipher_text.join(':')}] ciphertext"
				if cipher_text then
					cipher_text = cipher_text.map { |string_byte| string_byte.to_i.chr }
					puts decrypt(key, cipher_text.join)
				else 
					puts "cipher_text is nil"
				end

				#Thread.new {
				#	input = gets.strip
				#	puts "Enter Message"
				#	client.puts(input)
				#}

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

start('localhost', 20000)
