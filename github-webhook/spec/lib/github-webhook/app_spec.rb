require 'spec_helper'
require 'stringio'

require 'github-webhook/app'

describe "GithubWebhook::App" do
	subject { GithubWebhook::App.new }

	describe "#call" do
		before :each do
			redis = double
			allow(Redis).to receive(:new).and_return(redis)

			allow(redis).to receive(:publish) do |chan, message|
				@chan = chan
				@message = message
			end
		end

		let(:env)do
			{
				"HTTP_X_GITHUB_EVENT" => "the-github-event",
				"rack.input" => StringIO.new(payload)
			}
		end

		let(:payload) do
			{
				:after => 'after-sha',
				:repository => {
					:git_url => "a-git-url",
				},
				:head_commit => {
					:message => "the commit message",
					:author => {
						:name => "their name",
						:email => "author@email.com"
					}
				},
				:other => "stuff"
			}.to_json
		end

		it "processes the parsed JSON and publishes a message" do
			status, headers, bodies = subject.call(env)
			expect(bodies).to eq []
			expect(headers).to eq({})
			expect(status).to eq 200

			expect(@chan).to eq "task-finished"
			
			facts = JSON.parse(@message)

			expect(facts["source"]).to eq "github-webhook"

			build = facts["build"]
			expect(build["sha"]).to eq "after-sha"
			expect(build["repo"]).to eq "a-git-url"
			expect(build["message"]).to eq "the commit message"
			expect(build["author"]).to eq "their name"
			expect(build["author_email"]).to eq "author@email.com"
		end

		context "when there is an exception" do
			before do
				allow(Redis).to receive(:new).and_raise("An Exception")
			end

			it "responds with error message" do
				status, headers, bodies = subject.call(env)
				expect(bodies).to eq ["An Exception"]
				expect(headers).to eq({})
				expect(status).to eq 500
			end
		end
	end
end
