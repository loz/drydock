require 'json'
require 'yaml'
require 'logger'

require 'nsq'

NSQD = "#{ENV["NSQD_PORT_4150_TCP_ADDR"]}:#{ENV["NSQD_PORT_4150_TCP_PORT"]}"

Nsq.logger = Logger.new(STDOUT)

class App
	def run
		puts 'Starting'
		loop do
			begin
			puts 'Popping'
			puts consumer.size
			msg = consumer.pop
			facts = JSON.parse(msg.body)
			trigger_build(facts)
			msg.finish
			rescue => e
				puts e.message
			end
		end
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

	def trigger_build(facts)
		cmd = "docker run -d --link nsqd:nsqd -v /root/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock git-checkout #{facts["repo"]}"
		puts "Running #{cmd}"
		puts `#{cmd}`
	end

end

App.new.run
