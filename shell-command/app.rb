$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__),'./lib'))

require 'shell-command'

ShellCommand::App.new.run ARGV[0], ARGV[1]
