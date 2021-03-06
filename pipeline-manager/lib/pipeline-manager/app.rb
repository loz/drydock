require 'json'
require 'yaml'
require 'logger'
require 'open3'

require 'redis'

module PipelineManager
	autoload :Commands, 'pipeline-manager/commands'

  CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"
  
  class App
		attr_reader :commands

  	def run
			@commands = Commands.new(hub)
  		send_replace_signal
  		watch_messages
  	end

		private
  
  	def watch_messages
  		puts 'Subscribing..'
  		hub.subscribe("task-finished", "commands") do |on|
  			on.message do |channel, message|
  				begin
  				puts "Message on #{channel}"
  				case channel
  				when 'task-finished'
  					handle_task(message)
  				when 'commands'
						commands.handle(message)
  				end
  				STDOUT.flush
  				rescue => e
  					puts 'Sub err:' + e.message
  				end
  			end
  		end
  	end
  
  	def handle_task(message)
  		msg = JSON.parse(message)
  		source = msg["source"]
  		handle_source(source, msg)
  	rescue => e
  		puts e.message
  	end
  
  	def redis
  		Redis.new(:url => CONN_STRING)
  	end
  
  	def hub
  		@hub ||= redis
  	end
  
  	def send_replace_signal
  		puts 'Sending replace signal..'
  		redis.publish 'commands', 'replace-pipeline'
  	end
  
  	def handle_source(type, msg)
  		puts "Message: #{type} -> #{msg.inspect}"
  		case type
  		when 'github-webhook'
  			clone_repo(msg)
  		when 'git-checkout'
  			manual_build(msg)
  		when 'shell-command'
  			build_complete(msg)
  		end
  	rescue => e
  		puts e.message
  	end
  
  	def clone_repo(facts)
  		build = facts["build"]
  		buildid = build["sha"]
  		puts redis.set buildid, build.to_json
  		cmd = "docker run -d --link redis:redis -v /root/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock git-checkout #{buildid}"
  		puts "Running #{cmd}"
  		working = `#{cmd}`
  		build["working"] = working.chomp("\n")
  		puts redis.set buildid, build.to_json
  	end
  
  	def manual_build(msg)
  		p "Manual Build", msg
  		buildid = msg["buildid"]
  		build = JSON.parse(redis.get(buildid))
  		working = build["working"]
  		cmd = "docker run -d -v /root/.ssh:/root/.ssh --link redis:redis -v /var/run/docker.sock:/var/run/docker.sock --volumes-from #{working} shell-command #{buildid} ./manual-cd.sh"
  		puts "Running #{cmd}"
  		puts `#{cmd}`
  	end
  
  	def build_complete(msg)
  		p "Build Complete!", msg
  		buildid = msg["buildid"]
  		build = {"buildid" => buildid}
  		puts redis.publish 'build-finished', build.to_json
  	end
  
  end
end
