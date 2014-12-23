require 'json'
require 'yaml'
require 'logger'
require 'redis'

CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"

class App
	def run(buildid)
		puts "Receiving Build: #{buildid}"
		build = JSON.parse(pubhub.get(buildid))
		perform_build(build)
	end

	def pubhub
		@pubhub ||= Redis.new(:url => CONN_STRING)
	end

	def perform_build(build)
		puts build.to_yaml
		repo = build["repo"]
		puts "Cloning #{repo}"
		puts `git clone #{repo} /working`
		Dir.chdir("/working/")
		puts `./manual-cd.sh`
	end

end

App.new.run ARGV[0]
