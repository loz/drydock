require 'spec_helper'
require 'webmock'
require 'webmock/rspec'

describe "PipelineManager::BuildSpec" do
	let(:klass) { PipelineManager::BuildSpec }
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

	let(:running_state) { double(:status => "running", :completed? => false) }
	let(:completed_state) { double(:completed? => true) }
	let(:failed_state) { double(:status => "failed", :completed? => true) }
	let(:success_state) { double(:status => "success", :completed? => true) }

	describe ".from_url" do
		let(:url) { "http://example.com/build.yaml" }
		subject { klass.from_url(url) }

		before :each do
			stub_request(:get, url).
				to_return(:status => 200, :body => yaml, :headers => {})
		end

		it "loads the specification from the url" do
			expect(subject.name).to eq "Example"
		end
	end

	describe ".from_yaml" do

		subject { klass.from_yaml(yaml) }

		it "creates a specification from the string" do
			expect(subject.name).to eq "Example"
		end

		describe "#next_steps" do
			context "with no prior state" do
				let(:state) { nil }

				it "includes steps with no dependencies" do
					steps = subject.next_steps(state)

					expect(steps.length).to eq 1
					step = steps.first

					expect(step.name).to eq 'first-one'
				end
			end

			context "with prior state" do
				let(:state) { {"first-one" => success_state}}

				it "includes steps with satisfied dependencies" do
					steps = subject.next_steps(state)

					expect(steps.length).to eq 1
					step = steps.first

					expect(step.name).to eq 'second-one'
				end

				it "does not include steps not satisfied" do
					state = { "first-one" => running_state }
					expect(subject.next_steps(state).length).to eq 0
				end
			end
		end

		describe "#completed?" do
			context "when there are more steps" do
				let(:state) { nil }

				it "is not completed" do
					expect(subject.completed?(state)).to be false
				end
			end

			context "when there are no more steps" do
				context "and some are running" do
					let(:state) { { "first-one" => running_state } }

					it "is not complete" do
						expect(subject.completed?(state)).to be false
					end
				end

				context "and all have run" do
					let(:state) { { "first-one" => completed_state , "second-one" => completed_state } }

					it "is complete" do
						expect(subject.completed?(state)).to be true
					end
				end
			end
		end

		describe "#succeeded?" do
			context "when all tasks are completed" do
				let(:state) { { "first-one" => success_state, "second-one" => success_state } }

				it "is successful" do
					expect(subject.succeeded?(state)).to be true
				end
			end

			context "when one or more tasks is failed" do
				let(:state) { { "first-one" => success_state, "second-one" => failed_state } }

				it "is not successful" do
					expect(subject.succeeded?(state)).to be false
				end
			end
		end
	end
end
