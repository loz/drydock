require 'json'
require 'yaml'
require 'logger'
require 'redis'

CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"

class App
	def run(buildid, cmd)
		puts "Receiving Build: #{buildid}"
		run_command(cmd)
		notify_success(buildid)
	end

	def pubhub
		Redis.new(:url => CONN_STRING)
	end

	def notify_success(buildid)
		message = {
			:source => 'shell-command',
			:buildid => buildid,
			:status => 'success'
		}
		puts "Notify 'task-finished' -> #{message.inspect}"
		puts pubhub.publish 'task-finished', message.to_json
	rescue => e
		puts e.message
	end

	def run_command(cmd)
		Dir.chdir "/working" do
			puts "running #{cmd}"
			puts `#{cmd}`
		end
	end

end

App.new.run ARGV[0], ARGV[1]
