#!/usr/bin/env ruby

require 'engine'

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
