require 'rack'
require 'json'
require 'yaml'

require 'redis'

CONN_STRING = "redis://#{ENV["REDIS_PORT_6379_TCP_ADDR"]}:#{ENV["REDIS_PORT_6379_TCP_PORT"]}/0"

class App
	def call(env)
		req = Rack::Request.new(env)
		payload = JSON.parse(req.body.read)
		facts = extract_facts(payload, req)
		message = {
			:source => 'github-webhook',
			:build => facts,
			:status => 'success'
		}
		pubhub.publish 'task-finished', message.to_json
		return [200, {}, []]
	rescue => e
		return [500, {}, [e.message]]
	end

	def pubhub
		@pubhub ||= Redis.new(:url => CONN_STRING)
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
