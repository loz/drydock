#!/usr/bin/env bash
#This is a simple manual cd script to bootstrap up something more sophisticated

report() {
	if [ "$2" -eq 0 ]; then
		echo -e "\033[0;32m$1 PASSED\033[0m"
	else
		echo -e "\033[0;31m$1 FAILED\033[0m"
	fi
}

docker_logs() {
	echo -e "\033[0;36mDocker Logs For $1\033[0m"
	echo -e "\033[0;33m"
	docker logs $1
	echo -e "\033[0m"
}

dockerImage() {
	echo -e "Building $1"
	pushd $1
		docker build -t $1 .
		status=$?
	popd
	report "dockerImage" $status
  return $status
}

testSuite() {
	docker run --rm github-webhook bundle exec rspec
	status=$?
	report "testSuite" $status
	return $status
}

deploy() {
	docker rm -f github-webhook
	docker run --name github-webhook -d \
		--env="VIRTUAL_HOST=github-webhook.services.mrloz.xyz" \
		--env="VIRTUAL_PORT=3000" \
		--link nsqd:nsqd \
		-v /root/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock \
		github-webhook
	docker rm -f pipeline-manager
	docker run --name pipeline-manager -d \
		--link nsqd:nsqd \
		-v /root/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock \
		pipeline-manager
		
}

dockerImage 'github-webhook' &&
dockerImage 'pipeline-manager' &&
dockerImage 'git-checkout' &&
testSuite &&
deploy &&
echo "SUCCESS"
