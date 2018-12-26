require 'encrypted_instant_messaging'
require 'engine'

include EncryptedInstantMessaging::Engine

class ClientManager

	def initialize(key)
		@key = key
		@mutex = Mutex.new
		@logger = Logger.new(STDOUT)
		@logger.level = Logger::DEBUG
		@clients = []
	end

	def add_client(client)
		@mutex.synchronize do
			@clients << client
		end 
	end

	def remove_client(client)
		@mutex.synchronize do
			@clients = @clients - [client]
		end
	end

	def broadcast_messages(msg)
		@mutex.synchronize do
			hmac = OpenSSL::HMAC.digest('SHA512', @key, msg)
			full_msg = msg + hmac

			cipher_text = []
			encrypt(@key, full_msg).bytes { |byte| cipher_text << byte }
			ct = cipher_text.join(':') + "\n"
			@logger.debug "Forwarding encrypted message to #{@clients.length} clients"
			@clients.each { |client| client.send(ct,0) }
		end
	end
end