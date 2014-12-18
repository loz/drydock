require 'rack'
require 'json'

class App
	def call(env)
		logger = env["rack.logger"]
		logger.info "Called!"
		req = Rack::Request.new(env)
		payload = JSON.parse(req.body.read)
		logger.info payload
		return [200, {}, []]
	rescue => e
		return [500, {}, [e.message]]
	end

		
end
