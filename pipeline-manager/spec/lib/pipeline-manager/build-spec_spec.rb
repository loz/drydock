require 'spec_helper'

describe "PipelineManager::BuildSpec" do
	let(:klass) { PipelineManager::BuildSpec }

	describe ".from_yaml" do
		let(:yaml) do
			<<-YAML
name: Example
steps:
  first-one:
    image: an-image
    ssh: true
  second-one:
    dependencies:
    - first-one
    image: other-image
    docker: true
    volumes:
    - first-one
    args: bla bla
			YAML
		end

		subject { klass.from_yaml(yaml) }

		it "creates a specification from the string" do
			expect(subject.name).to eq "Example"
		end
	end
end
