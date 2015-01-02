require 'spec_helper'
require 'stringio'
require 'shell-command/app'

describe "ShellCommand::App" do
	let(:buildid) { "a-build-id" }
	let(:cmd) { "some-command" }

	let(:stdout) { "(stdout)" }
	let(:stderr) { "(stderr)" }
	let(:status) { double }
	let(:redis) { double }

	subject { ShellCommand::App.new }

	describe "#run" do
		before :each do
			allow(Redis).to receive(:new).and_return(redis)

			allow(redis).to receive(:publish)
			expect(Open3).to receive(:capture3).with(cmd).
				and_return([stdout, stderr, status])
			expect(Dir).to receive(:chdir).with("/working").and_yield
		end

		describe "with success" do
			before :each do
				allow(status).to receive(:success?).and_return(true)
			end

			it "runs the command in /working folder" do
				subject.run(buildid, cmd)
			end
				
			it "notifies a success" do
				success_json = {
					:source => 'shell-command',
					:buildid => buildid,
					:status => 'success'
				}.to_json
				expect(redis).to receive(:publish).with("task-finished", success_json)
				subject.run(buildid, cmd)
			end

		end

		context "when the clone process exits non-zero" do
			before :each do
				allow(status).to receive(:success?).and_return(false)
			end

			it "notifies a failure.." do
				failed_json = {
					:source => 'shell-command',
					:buildid => buildid,
					:status => 'failed'
				}.to_json
				expect(redis).to receive(:publish).with("task-finished", failed_json)
				subject.run(buildid, cmd)
			end
		end
	end
end
