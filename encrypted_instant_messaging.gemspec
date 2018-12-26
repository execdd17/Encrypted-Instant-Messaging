$:.unshift File.expand_path('../lib', __FILE__)
require 'encrypted_instant_messaging/version'

Gem::Specification.new do |s|
  s.name        = 'genetic_algorithms'
  s.version     = EncryptedInstantMessaging::VERSION
  s.authors     = ["Alexander Vanadio"]
  s.email       = 'execdd17@gmail.com'
  s.homepage    = 'https://github.com/execdd17/genetic_algorithms'
  s.summary     = "An encrypted messaging system"

  s.executables << 'server'
  s.executables << 'client'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency("openssl")
  s.add_development_dependency("rspec", "~> 2.14")
  s.add_development_dependency("simplecov", "~> 0.8")
end