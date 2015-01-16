require 'yaml'
require 'net/http'
						
module PipelineManager
	class Step
		attr_reader :name

		def initialize(details)
			@name, @spec = details
		end

		def ready?(state)
			if state
				!already_launched?(state) &&
				dependencies_satisfied?(state)
			else
				dependencies.empty?
			end
		end

		private

		def dependencies
			@spec["dependencies"] || []
		end

		def dependencies_satisfied?(state)
			dependencies.all? { |d| state[d] == "success" }
		end

		def already_launched?(state)
			state[name]
		end
	end

	class BuildSpec

		def self.from_yaml(yml)
			new YAML.load(yml)
		end

		def self.from_url(url)
			uri = URI(url)
			yaml = Net::HTTP.get(uri)
			from_yaml(yaml)
		end

		def initialize(structure)
			@structure = structure
		end

		def name
			@structure["name"]
		end

		def next_steps(state)
			steps.select { |s| s.ready?(state) }
		end

		def completed?(state)
			todo = next_steps(state)
			todo.empty? && all_finished?(state)
		end

		def succeeded?(state)
			state.values.all? { |s| s == "complete" }
		end

		private

		def all_finished?(state)
			!state.values.any? {|s| s == "running" }
		end

		def steps
			@steps ||= @structure["steps"].map do |s|
				Step.new(s)
			end
		end

	end
end
