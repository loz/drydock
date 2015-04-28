require 'json' 

class PipelineManager::Build
	attr_reader :id, :started

	def self.find_or_create(buildid, options = {})
		redis = options[:redis]
		meta = redis.get("builds/#{buildid}/meta")
		if meta.nil?
			meta = {
				"id" => buildid,
				"started" => Time.now.to_s
			}
		else
			meta = JSON.parse(meta)
		end

		new(meta, redis)
	end

	def initialize(attrs = {}, connection)
		@id = attrs["id"]
		@started = Time.parse(attrs["started"])
		@connection = connection
	end

	def save(redis)
		key = "builds/#{id}"
		redis.set("#{key}/meta", meta.to_json)
	end

	def state
		@state ||= fetch_build_state
	end

	def update_step(step, attrs)
		status = state[step]
		status.update(attrs)
		status.marshal("builds/#{id}/steps/#{step}", @connection)
	end

	private

	def fetch_build_state
		spec = fetch_build_spec
		state = {}
		spec.steps.each do |step|
			state[step.name] = fetch_step_state(step.name)
		end
		state
	end

	def fetch_build_spec
		return @spec if @spec
		spec = @connection.get("builds/#{id}/spec")
		@spec = PipelineManager::BuildSpec.from_yaml(spec)
	end

	def fetch_step_state(step)
		state = @connection.get("builds/#{id}/steps/#{step}")
		State.new(JSON.parse(state)) if state
	end

	def meta
		{
			"id" => id,
			"started" => started
		}
	end

	class State
		def initialize(attrs)
			@attrs = attrs
		end

		def success?
			@attrs["status"] == "success"
		end

		def failed?
			@attrs["status"] == "failed"
		end

		def container
			@attrs["container"]
		end

		def completed?
			@attrs["status"] != "running"
		end
		
		def update(attrs)
			@attrs.merge! attrs
		end

		def meta(attr)
			@attrs[attr]
		end

		def marshal(key, store)
			store.set(key, @attrs.to_json)
		end
	end
end
