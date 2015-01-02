require 'json'
require 'yaml'
require 'logger'
require 'redis'
require 'open3'

module GitCheckout
  CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"
  
  class App
  	def run(buildid)
  		puts "Receiving Build: #{buildid}"
  		build = JSON.parse(pubhub.get(buildid))
  		if clone_source(build)
  			notify('success', buildid)
  			await_finish(buildid)
  		else
  			notify('failed', buildid)
  		end
  	end
  
  	def pubhub
  		Redis.new(:url => CONN_STRING)
  	end
  
  	def notify(status, buildid)
  		message = {
  			:source => 'git-checkout',
  			:buildid => buildid,
  			:status => status
  		}
  		puts "Notify 'task-finished' -> #{message.inspect}"
  		puts pubhub.publish 'task-finished', message.to_json
  	end
  
  	def await_finish(buildid)
  		puts "Waiting for build finsih to clean up.."
  		conn = pubhub
  		conn.subscribe("build-finished") do |on|
  			on.message do |channel, message|
  				puts "Message Recieved: #{channel}, #{message}"
  				build = JSON.parse(message)
  				conn.unsubscribe if build["buildid"] == buildid
  			end
  		end
  		puts "Finishing up..."
  	end
  
  	def clone_source(build)
  		puts build.to_yaml
  		repo = build["repo"]
  		puts "Cloning #{repo}"
  		cmd = "git clone --depth 1 #{repo} /working"
  		stdout, stderr, status = Open3.capture3(cmd)
  		puts stdout
  		if status.success?
  			puts 'Clone successfully'
  			true
  		else
  			puts 'Clone failed'
  			puts stderr
  			false
  		end
  	end
  
  end
end

