require 'socket'
require 'engine'

#if ARGV.length != 1 then
#	puts "Usage: #{$0} [key]"
#	exit
#end

loop do
	streamSock = TCPSocket.new( "127.0.0.1", 20000 )
	key = ARGV[0]

	#Thread.new do
		print "Enter Message: "
		plain_text = STDIN.gets.strip
		cipher_text = []
		encrypt("key", plain_text).bytes { |byte| cipher_text << byte }
		ct = cipher_text.join(':') + "\n"
		puts "Sending [#{ct.chomp}]"
		streamSock.send(ct,0)
		puts "Sent!"
	#end

	#str = streamSock.recv(100)
	#print str
	streamSock.close
end

