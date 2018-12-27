class Message 
	MAX_SENDER_SIZE = 20

	def self.create_message(sender, payload, hmac)
		raise "Sender is too long" if sender.length > MAX_SENDER_SIZE
		raise "sender can not be empty" if sender.empty?
		raise "sender can't be nil" if sender.nil?
		raise "payload can't be nil" if payload.nil? 
		raise "hmac can't be nil" if hmac.nil?

		Message.new(sender, payload, hmac)
	end

	def self.parse_message(plaintext)
		sender_start = 0
		sender_end = MAX_SENDER_SIZE
		sender = plaintext.slice(sender_start, sender_end)

		hmac_start = plaintext.length-64
		hmac_end = plaintext.length-1
		hmac = plaintext.slice(hmac_start..hmac_end)

		payload = plaintext.slice(sender_end..(hmac_start-1))
		Message.new(sender.strip, payload, hmac)
	end

	def serialize
		"%-#{MAX_SENDER_SIZE}s" % @sender + @payload + @hmac
	end

	def to_s
		"#{sender.upcase}: #{payload}"
	end

	attr_reader :sender, :payload, :hmac

	private 

	def initialize(sender, payload, hmac)
		@sender = sender
		@payload = payload
		@hmac = hmac
	end

end