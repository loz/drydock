require 'spec_helper'
require 'stringio'

describe "App" do
	let(:buildid) { "a-build-id" }
	let(:build) do
		{
			:repo => 'git://example-url',
			:other => "stuff"
		}.to_json
	end

	let(:stdout) { "(stdout)" }
	let(:stderr) { "(stderr)" }
	let(:status) { double }
	let(:redis) { double }

	subject { App.new }

	describe "#run" do
		before :each do
			allow(Redis).to receive(:new).and_return(redis)

			allow(redis).to receive(:subscribe)
			allow(redis).to receive(:publish)
			allow(redis).to receive(:get).with(buildid).and_return(build)
			expect(Open3).to receive(:capture3).
				with("git clone --depth 1 git://example-url /working").
				and_return([stdout, stderr, status])
		end

		describe "with success" do
			before :each do
				allow(status).to receive(:success?).and_return(true)
			end

			it "clones the git repository from build data url" do
				subject.run(buildid)
			end
				
			it "notifies a success" do
				success_json = {
					:source => 'git-checkout',
					:buildid => buildid,
					:status => 'success'
				}.to_json
				expect(redis).to receive(:publish).with("task-finished", success_json)
				subject.run(buildid)
			end

			it "waits for build completion to exit" do
				on = double
				expect(redis).to receive(:subscribe).with("build-finished").and_yield(on)
				watch = nil
				expect(on).to receive(:message) do |&block|
					watch = block
				end
				subject.run(buildid)
				
				ignore = {:buildid => 'unknown'}.to_json
				watch.call('channel', ignore)

				expect(redis).to receive(:unsubscribe)
				matched = {:buildid => buildid}.to_json
				watch.call('channel', matched)
			end
		end

		context "when the clone process exits non-zero" do
			before :each do
				allow(status).to receive(:success?).and_return(false)
			end

			it "notifies a failure.." do
				failed_json = {
					:source => 'git-checkout',
					:buildid => buildid,
					:status => 'failed'
				}.to_json
				expect(redis).to receive(:publish).with("task-finished", failed_json)
				subject.run(buildid)
			end
		end
	end
end
