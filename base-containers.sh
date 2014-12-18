docker run --name container-proxy -d -v /var/run/docker.sock:/tmp/docker.sock -p 80:80 navyproject/container-proxy
