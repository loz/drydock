require File.join(File.dirname(__FILE__),'app')

use Rack::Logger
run App.new
