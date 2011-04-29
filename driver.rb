#!/usr/bin/env ruby

require 'engine'
require 'socket'

def usage
	puts "usage: #{$0} [encrypt|decrypt] [key] [text]"
	exit
end

usage unless ARGV.length == 3



case ARGV.shift
  when "encrypt" then 
	  key, plain_text = ARGV.shift, ARGV.shift
	  cipher_text = []
	  encrypt(key, plain_text).bytes { |byte| cipher_text << byte }
	  puts cipher_text.join(':')
  when "decrypt" then
	key, cipher_text= ARGV.shift, ARGV.shift.split(':')
	cipher_text = cipher_text.map { |string_byte| string_byte.to_i.chr }
	puts decrypt(key, cipher_text.join)
  else usage
end

dts = TCPServer.new('localhost', 20000)
loop do
	Thread.start(dts.accept) do |s|
	print(s, " is accepted\n")
	s.write(Time.now)
	print(s, " is gone\n")
	s.close
	end
end
