require 'nsq'

consumer = Nsq::Consumer.new(
  nsqd: '172.17.2.6:4150',
	topic: 'trigger',
	channel: 'a-channel'
)

msg = consumer.pop
puts msg.body
msg.finish

consumer.terminate
