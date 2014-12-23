require 'json'
require 'yaml'
require 'logger'

require 'nsq'

NSQD = "#{ENV["NSQD_PORT_4150_TCP_ADDR"]}:#{ENV["NSQD_PORT_4150_TCP_PORT"]}"

Nsq.logger = Logger.new(STDOUT)

100.times { puts 'flushing' }

class App
	def run
		puts 'Starting'
		loop do
			puts 'Popping'
			puts consumer.size
			facts = JSON.parse(consumer.pop)
			perform_build(facts)
			msg.finish
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

	def perform_build(facts)
		puts `git clone #{facts[:repo]} source`
		Dir.chdir("source/")
		puts `./manual-cd.sh`
	end

end

App.new.run
