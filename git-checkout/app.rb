require 'json'
require 'yaml'
require 'logger'
require 'nsq'

NSQD = "#{ENV["NSQD_PORT_4150_TCP_ADDR"]}:#{ENV["NSQD_PORT_4150_TCP_PORT"]}"

Nsq.logger = Logger.new(STDOUT)

class App
	def run(repo)
		puts "Cloning #{repo}"
		puts `git clone #{repo} /working`
		Dir.chdir("/working/")
		puts `./manual-cd.sh`
	end

	def consumer
		@consumer ||= Nsq::Consumer.new(
										:nsqd => NSQD,
										:topic  => 'trigger',
									  :channel => 'pipeline-manager'
					)
	end

	def producer
		@producer ||= Nsq::Producer.new(
			:nsqd => NSQD,
			:topic => "manager"
			)
	end

	def perform_build(facts)
	end

end

App.new.run ARGV[0]
