require 'nsq'

producer = Nsq::Producer.new(
  nsqd: '172.17.2.6:4150',
	topic: 'some-topic'
)

producer.write('one', 'two', 'three', 'four')

producer.terminate
