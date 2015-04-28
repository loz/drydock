$LOAD_PATH.unshift File.expand_path('./lib', File.dirname(__FILE__))

require 'git-checkout'

GitCheckout::App.new.run ARGV[0]
