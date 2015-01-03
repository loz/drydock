$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__), './lib')

require 'pipeline-manager'

GitCheckout::App.new.run
