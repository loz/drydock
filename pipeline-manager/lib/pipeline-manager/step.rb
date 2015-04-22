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

		def cmd(status)
			run = []
			run << "docker run -d"
			apply_docker(run)
			apply_ssh_creds(run)
			apply_volumes(run, status)
			run << image
			apply_args(run)
			run
		end

		def docker_required?
			@spec["docker"]
		end

		def ssh_required?
			@spec["ssh"]
		end

		private

		def apply_docker(run)
			if docker_required?
				run << "-v /var/run/docker.sock:/var/run/docker.sock"
			end
		end

		def apply_ssh_creds(run)
			if ssh_required?
				run << "-v /root/.ssh:/root/.ssh"
			end
		end

		def apply_volumes(run, state)
			if volumes = @spec["volumes"]
				volumes.each do |volume|
				  status  = state[volume]
					run << "--volumes-from #{status.container}"
				end
			end
		end
		
		def apply_args(run)
			if @spec["args"]
				run << @spec["args"]
			end
		end

		def image
			@spec["image"]
		end

		def dependencies
			@spec["dependencies"] || []
		end

		def dependencies_satisfied?(state)
			dependencies.all? { |d| state[d].status == "success" }
		end

		def already_launched?(state)
			state[name]
		end
	end
end
