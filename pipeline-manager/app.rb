require 'json'
require 'yaml'
require 'logger'

require 'redis'

CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"

class App
	def run
		puts 'Starting'
		pubhub.subscribe("trigger") do |on|
			on.message do |channel, message|
				facts = JSON.parse(message)
				trigger_build(facts)
			end
		end
	rescue => e
		puts e.message
		sleep 1
		retry
	end

	def pubhub
		Redis.new(:url => CONN_STRING)
	end

	def trigger_build(facts)
		build = facts["build"]
		buildid = build["sha"]
		puts pubhub.set buildid, build.to_json
		cmd = "docker run -d --link redis:redis -v /root/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock git-checkout #{buildid}"
		puts "Running #{cmd}"
		puts `#{cmd}`
	end

end

App.new.run
