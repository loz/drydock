module PipelineManager
	class Commands
		attr_reader :hub

		def initialize(hub)
			@hub = hub
		end

		def handle(cmd)
  		puts "Command Recieved: #{cmd}"
  		case cmd
  		when 'replace-pipeline'
  			puts "Being Replaced, Shutting down..."
  			hub.unsubscribe
  		end
		end
	end
end
