require 'encrypted_instant_messaging'
require 'engine'

include EncryptedInstantMessaging::Engine

class ClientManager

	def initialize
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

	def broadcast_messages(msg, source)
		@mutex.synchronize do
			targets = (@clients - [source]) || []
			@logger.debug "Forwarding encrypted message #{msg} to #{targets.length} clients"
			targets.each { |client| client.send(msg,0) }
		end
	end
end