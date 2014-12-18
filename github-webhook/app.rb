require 'rack'

class App
	def call(env)
		logger = env["rack.logger"]
		logger.info "Called!"
		req = Rack::Request.new(env)
		logger.info req.body
		return [200, {}, []]
	end

		
end
