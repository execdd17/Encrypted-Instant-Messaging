require 'openssl'

module EncryptedInstantMessaging
	module Engine
		def aes(m,k,t)
			  (aes = OpenSSL::Cipher.new('aes-256-cbc').send(m)).key = Digest::SHA256.digest(k)
			    aes.update(t) << aes.final
		end

		def encrypt(key, text)
			  aes(:encrypt, key, text)
		end

		def decrypt(key, text)
			  aes(:decrypt, key, text)
		end

		if $0 == __FILE__
			  p "text" == decrypt("key", encrypt("key", "text"))
		end
	end
end 