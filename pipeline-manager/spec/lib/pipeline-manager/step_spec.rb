require 'spec_helper'

describe "Step" do
	let(:spec) do
		{
			"dependencies" => [],
			"image" => "some-image"
		}
	end

	let(:status) do
		{
			"some-step" => PipelineManager::Build::State.new("status" => "running", "container" => "asha")
		}
	end

	subject { PipelineManager::Step.new(["thename", spec]) }

	describe "#cmd" do
		it "runs docker detatched" do
			cmd = subject.cmd(status)

			expect(cmd[0]).to eq "docker run -d"
		end

		it "links to redis" do
			cmd = subject.cmd(status)

			expect(cmd[1]).to eq "--link=redis:redis"
		end

		it "uses the image" do
			cmd = subject.cmd(status)

			expect(cmd[-1]).to eq "some-image"
		end

		context "when docker is required" do
			before :each do
				spec["docker"] = true
			end

			it "binds the docker socket" do
				cmd = subject.cmd(status)

				expect(cmd).to include "-v /var/run/docker.sock:/var/run/docker.sock"
			end
		end

		context "when volumes are required" do
			before :each do
				spec["volumes"] = ["some-step"]
			end

			it "attaches the running volume" do
				cmd = subject.cmd(status)

				expect(cmd).to include "--volumes-from asha"
			end
		end

		context "when args are supplied" do
			before :each do
				spec["args"] = "some args"
			end

			it "runs image with additional arguments" do
				cmd = subject.cmd(status)

				expect(cmd[-1]).to eq "some args"
			end
		end

		context "when ssh credentials required" do
			before :each do
				spec["ssh"] = true
			end

			it "binds the .ssh folder" do
				cmd = subject.cmd(status)

				expect(cmd).to include "-v /root/.ssh:/root/.ssh"
			end
		end
	end

"
  second-one:
    dependencies:
    - first-one
    image: other-image
    docker: true
    volumes:
    - first-one
    args: bla bla
"
end
