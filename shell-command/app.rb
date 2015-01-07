$LOAD_PATH.unshift File.expand_path('./lib', File.dirname(__FILE__))

require 'shell-command'

ShellCommand::App.new.run ARGV[0]
