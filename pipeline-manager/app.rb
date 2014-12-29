require 'json'
require 'yaml'
require 'logger'

require 'redis'

CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"

class App
	def run
		send_replace_signal
		threads = []
		threads << watch_tasks
		threads << watch_commands
		threads.map &:join
	end

	def watch_tasks
		hub = taskhub
		Thread.new do
			puts 'Watching Tasks..'
			hub.subscribe("task-finished") do |on|
				on.message do |channel, message|
					msg = JSON.parse(message)
					source = msg["source"]
					handle_source(source, msg)
				end
			end
		end
	rescue => e
		puts e.message
		sleep 1
		retry
	end

	def watch_commands
		hub = cmdhub
		Thread.new do
			puts 'Watching Commands..'
			hub.subscribe("commands") do |on|
				on.message do |channel, message|
					handle_command(msg)
				end
			end
		end
	rescue => e
		puts e.message
		sleep 1
		retry
	end

	def redis
		Redis.new(:url => CONN_STRING)
	end

	def taskhub
		@taskhub ||= Redis.new(:url => CONN_STRING)
	end

	def cmdhub
		@cmdhub ||= Redis.new(:url => CONN_STRING)
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
	end

	def handle_command(cmd)
		puts "Command Recieved: #{cmd}"
		case cmd
		when 'replace-pipeline'
			puts "Being Replaced..."
			cmdhub.unsubscribe
			taskhub.unsubscribe
		end
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
		cmd = "docker run -d -v /root/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock --volumes-from #{working} shell-command #{buildid} ./manual-cd.sh"
		puts "Running #{cmd}"
		`#{cmd}`
	end

	def build_complete(msg)
		p "Build Complete!", msg
		buildid = msg["buildid"]
		build = {"buildid" => buildid}
		puts redis.publish 'build-finished', build.to_json
	end

end

App.new.run
