$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))             
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib/encrypted_instant_messaging'))

module EncryptedInstantMessaging
  require 'encrypted_instant_messaging/engine'	
  require 'encrypted_instant_messaging/client_manager'		
end