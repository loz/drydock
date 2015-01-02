$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__), './lib')

require 'git-checkout'

GitCheckout::App.new.run ARGV[0]
