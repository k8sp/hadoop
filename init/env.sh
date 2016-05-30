#!/bin/bash
# add proxy below to enable proxies
#export HTTP_PROXY=<http://PROXYHOST:PORT>
#export HTTPS_PROXY=<https://PROXYHOST:PORT>
#export KUBERNETES_HTTP_PROXY=<http://PROXYHOST:PORT>
#export KUBERNETES_HTTPS_PROXY=<https://PROXYHOST:PORT>

export MASTER_IP=172.24.3.164

export K8S_VERSION=1.2.0
export ETCD_VERSION=2.2.1
export FLANNEL_VERSION=0.5.5
export FLANNEL_IFACE=eth1
export FLANNEL_IPMASQ=true
# uncomment this to enable start a bootstrap docker daemon at /var/run/bootstrap-docker.sock
# and start flannel under it
#export BOOTSTRAP_FLANNEL=false
export FLANNEL_DOCKER_SOCK=unix:///var/run/early-docker.sock
#export FLANNEL_DOCKER_SOCK=unix:///var/run/docker-bootstrap.sock
