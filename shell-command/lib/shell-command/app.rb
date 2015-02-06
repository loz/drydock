require 'json'
require 'yaml'
require 'logger'
require 'redis'
require 'open3'

module ShellCommand
  CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"
  
  class App
  	def run(buildid, cmd)
  		puts "Receiving Build: #{buildid}"
  		if run_command(cmd)
  			notify('success', buildid)
			else
  			notify('failed', buildid)
			end
  		STDOUT.flush
  	end
  
  	def pubhub
  		Redis.new(:url => CONN_STRING)
  	end
  
  	def notify(status, buildid)
  		message = {
  			:source => 'shell-command',
  			:buildid => buildid,
  			:status => status
  		}
  		puts "Notify 'task-finished' -> #{message.inspect}"
  		puts pubhub.publish 'task-finished', message.to_json
  	end
  
  	def run_command(cmd)
			stdout, stderr, status = nil
  		Dir.chdir "/working" do
  			puts "running #{cmd}"
				#stdout, stderr, status = Open3.capture3(cmd)
				stdin, stdout, stderr, wait_thread = Open3.popen3(cmd)
				while wait_thread.alive?
					streams = IO.select([stdout, stderr])
					stream = streams[0][0]
					puts stream.readline
					STDOUT.flush
				end
				status = wait_thread.value
  		end
			puts "outside again..."
			#puts stdout
			return true if status.success?
			#puts stderr
			false
  	end
  
  end

end
