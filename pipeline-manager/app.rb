$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__),'./lib'))

require 'pipeline-manager'

PipelineManager::App.new.run
