$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__), './lib')
require 'github-webhook'

use Rack::Logger
run GithubWebhook::App.new
