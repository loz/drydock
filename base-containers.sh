docker run --name container-proxy -d -v /var/run/docker.sock:/tmp/docker.sock -p 80:80 navyproject/container-proxy
docker run -d --name nsqlookupd dockerfile/nsq nsqlookupd
docker run -d --name nsqadmin --link nsqlookupd:nsqlookupd \
	-e "VIRTUAL_HOST=nsqadmin.services.mrloz.xyz" -e "VIRTUAL_PORT=4171" \
 dockerfile/nsq	nsqadmin --lookupd-http-address nsqlookupd:4161
docker run -d --name nsqd --link nsqlookupd:nsqlookupd dockerfile/nsq nsqd --data-path /data --lookupd-tcp-address nsqlookupd:4160
