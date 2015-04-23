require 'spec_helper'

describe "PipelineManager::Build" do
	let(:klass) { PipelineManager::Build }
	let(:redis) { double }

	before :each do
		@store = {}
		allow(redis).to receive(:get) do |key|
			@store[key]
		end

		allow(redis).to receive(:set) do |key, value|
			@store[key] = value
		end
	end

	describe ".find_or_create" do

		context "when the build does not exist" do

			it "creates a new build" do

				build = klass.find_or_create("a-build-id", :redis => redis)
				expect(build.id).to eq "a-build-id"
				expect(build.started).to be_within(1).of Time.now
			end
		end

		context "when the build exists" do
			let(:meta) do
				{
					"started" => "2000-01-01 12:00:00"
				}
			end

			it "retrieves the existing build" do
				redis.set("builds/a-build-id/meta", meta.to_json)

				build = klass.find_or_create("a-build-id", :redis => redis)
				expect(build.started).to eq Time.parse(meta["started"])
			end
		end
	end

	describe "Persistance" do
		describe "#save" do
			it "stores the meta data" do
				build = klass.find_or_create("a-new-build", :redis => redis)
				build.save(redis)

				saved = klass.find_or_create("a-new-build", :redis => redis)
				expect(saved.started).to eq build.started
			end
		end
	end

	describe "#state" do
		let(:spec) do
			<<-YAML
name: Example
steps:
  step1:
    image: step1
  step2:
    image: step2
YAML
		end

		before :each do
			klass.find_or_create("a-build", :redis => redis)
			redis.set("builds/a-build/spec", spec)

			redis.set("builds/a-build/steps/step1", {:status => "success"}.to_json)
			redis.set("builds/a-build/steps/step2", {:status => "failed"}.to_json)
		end

		it "retrieves the state of each step" do
			build = klass.find_or_create("a-build", :redis => redis)

			state = build.state
			expect(state.length).to eq 2
			expect(state["step1"].success?).to eq true
			expect(state["step2"].failed?).to eq true
		end

		it "persists changes" do
			build = klass.find_or_create("a-build", :redis => redis)

			build.update_step("step1", "somemeta" => "avalue")

			build = klass.find_or_create("a-build", :redis => redis)
			state = build.state["step1"]

			expect(state.meta("somemeta")).to eq "avalue"
		end
	end
end
