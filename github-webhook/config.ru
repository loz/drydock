$LOAD_PATH.unshift File.expand_path('./lib', File.dirname(__FILE__))

require 'github-webhook'

use Rack::Logger
run GithubWebhook::App.new
