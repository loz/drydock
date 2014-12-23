require 'rack'
require 'json'
require 'yaml'

require 'nsq'

NSQD = "#{ENV["NSQD_PORT_4150_TCP_ADDR"]}:#{ENV["NSQD_PORT_4150_TCP_PORT"]}"

puts NSQD


class App
	def call(env)
		logger = env["rack.logger"]
		req = Rack::Request.new(env)
		payload = JSON.parse(req.body.read)
		facts = extract_facts(payload, req)
		con = producer
		con.write(facts.to_json)
		con.terminate
		return [200, {}, []]
	rescue => e
		return [500, {}, [e.message]]
	end

	def producer
		Nsq::Producer.new(
			:nsqd => NSQD,
			:topic => "trigger"
			)
	end

	def perform_build(facts)
		`git clone #{facts[:repo]} source`
		Dir.chdir("source/")
		`./manual-cd.sh`
	end

	def extract_facts(payload, request)
		facts = {}

		facts[:event] = request.env["HTTP_X_GITHUB_EVENT"]
		facts[:sha] = payload["after"]
		repo = payload["repository"] || {}
		facts[:repo] = repo["git_url"]
		commit = payload["head_commit"] || {}
		facts[:message] = commit["message"]
		author = commit["author"] || {}
		facts[:author] = author["name"]
		facts[:author_email] = author["email"]
		facts
	end
end
