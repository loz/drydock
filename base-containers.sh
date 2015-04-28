# HTTP Proxy, autoroutes
docker run --name container-proxy -d \
		-v /var/run/docker.sock:/tmp/docker.sock \
		-p 80:80 navyproject/container-proxy

# Redis
docker run -d --name redis redis

# Webhook for github
docker run --name github-webhook -d \
		--env="VIRTUAL_HOST=github-webhook.services.mrloz.xyz" \
		--env="VIRTUAL_PORT=3000" \
		--link redis:redis \
		-v /root/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock \
		github-webhook

# Pipeline Manager
docker run -d \
		--link redis:redis \
		-v /root/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock \
		pipeline-manager

# ElasticSearch (ELK)
#docker run -d -p 9200:9200 \
#		--name elasticsearch \
#		-p 9300:9300 \
#		-v /data:/data dockerfile/elasticsearch \
#		/elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml

# Kibana
#docker run --name kibana \
#	-d -p 8080:8080 \
#	--link elasticsearch:docker.mrloz.xyz \
#	clusterhq/kibana

# Logstash
#docker run --name logstash \
#	--link=elasticsearch:elasticsearch \
#	-v /data/log:/var/host_logs \
#	-v /data/nginx-logstash.conf:/etc/confd/templates/logstash.conf.tmpl:ro \
#	-d digitalwonderland/logstash

# Logstash
docker run --name logstash \
	-v $PWD/conf/logstash-stdout.conf:/etc/confd/templates/logstash.conf.tmpl:ro \
	-d digitalwonderland/logstash
