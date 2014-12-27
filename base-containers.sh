docker run --name container-proxy -d \
		-v /var/run/docker.sock:/tmp/docker.sock \
		-p 80:80 navyproject/container-proxy
docker run -d --name redis redis
docker run --name github-webhook -d \
		--env="VIRTUAL_HOST=github-webhook.services.mrloz.xyz" \
		--env="VIRTUAL_PORT=3000" \
		--link redis:redis \
		-v /root/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock \
		github-webhook
docker run --name pipeline-manager -d \
		--link redis:redis \
		-v /root/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock \
		pipeline-manager
