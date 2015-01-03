require 'yaml'
						
module PipelineManager
	class BuildSpec

		def self.from_yaml(yml)
			new YAML.load(yml)
		end

		def initialize(structure)
			@structure = structure
		end

		def name
			@structure["name"]
		end

	end
end
