#!/bin/bash

# Copyright 2015 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A script to the k8s worker in docker containers.
# Authors @wizard_cxy @resouer

set -e

# Make sure docker daemon is running
if ( ! ps -ef |grep `cat /var/run/docker.pid` | grep -v 'grep' &> /dev/null); then
    echo "Docker is not running on this machine!"
    exit 1
fi

# Make sure k8s version env is properly set
K8S_VERSION=${K8S_VERSION:-"1.2.0"}
FLANNEL_VERSION=${FLANNEL_VERSION:-"0.5.5"}
FLANNEL_IFACE=${FLANNEL_IFACE:-"eth0"}
FLANNEL_IPMASQ=${FLANNEL_IPMASQ:-"true"}
ARCH=${ARCH:-"amd64"}
FLANNEL_DOCKER_SOCK=${FLANNEL_DOCKER_SOCK:-"unix:///var/run/early-docker.sock"}
BOOTSTRAP_FLANNEL=${BOOTSTRAP_FLANNEL:-"false"}

# Run as root
if [ "$(id -u)" != "0" ]; then
    echo >&2 "Please run as root"
    exit 1
fi

# Make sure master ip is properly set
if [ -z ${MASTER_IP} ]; then
    echo "Please export MASTER_IP in your env"
    exit 1
fi

echo "K8S_VERSION is set to: ${K8S_VERSION}"
echo "FLANNEL_VERSION is set to: ${FLANNEL_VERSION}"
echo "FLANNEL_IFACE is set to: ${FLANNEL_IFACE}"
echo "FLANNEL_IPMASQ is set to: ${FLANNEL_IPMASQ}"
echo "MASTER_IP is set to: ${MASTER_IP}"
echo "ARCH is set to: ${ARCH}"

# Check if a command is valid
command_exists() {
    command -v "$@" > /dev/null 2>&1
}

lsb_dist=""

# Detect the OS distro, we support ubuntu, debian, mint, centos, fedora dist
detect_lsb() {
    case "$(uname -m)" in
        *64)
            ;;
        *)
            echo "Error: We currently only support 64-bit platforms."
            exit 1
            ;;
    esac

    if command_exists lsb_release; then
        lsb_dist="$(lsb_release -si)"
    fi
    if [ -z ${lsb_dist} ] && [ -r /etc/lsb-release ]; then
        lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
    fi
    if [ -z ${lsb_dist} ] && [ -r /etc/debian_version ]; then
        lsb_dist='debian'
    fi
    if [ -z ${lsb_dist} ] && [ -r /etc/fedora-release ]; then
        lsb_dist='fedora'
    fi
    if [ -z ${lsb_dist} ] && [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi

    lsb_dist="$(echo ${lsb_dist} | tr '[:upper:]' '[:lower:]')"

    case "${lsb_dist}" in
        amzn|centos|debian|ubuntu|coreos)
            ;;
        *)
            echo "Error: We currently only support ubuntu|debian|amzn|centos|coreos."
            exit 1
            ;;
    esac
}


# Start the bootstrap daemon
bootstrap_daemon() {
    # Detecting docker version so we could run proper docker_daemon command
    [[ $(eval "docker --version") =~ ([0-9][.][0-9][.][0-9]*) ]] && version="${BASH_REMATCH[1]}"
    local got=$(echo -e "${version}\n1.8.0" | sed '/^$/d' | sort -nr | head -1)
    if [[ "${got}" = "${version}" ]]; then
        docker_daemon="docker -d"
    else
        docker_daemon="docker daemon"
    fi
    ${docker_daemon} \
        -H $FLANNEL_DOCKER_SOCK \
        -p /var/run/docker-bootstrap.pid \
        --iptables=false \
        --ip-masq=false \
        --bridge=none \
        --graph=/var/lib/docker-bootstrap \
        --exec-root=/var/lib/docker-bootstrap \
            2> /var/log/docker-bootstrap.log \
            1> /dev/null &

    sleep 5
}

DOCKER_CONF=""

# Start k8s components in containers
start_flannel() {
    # Start flannel
    flannelCID=$(docker -H $FLANNEL_DOCKER_SOCK run \
        -d \
        --restart=on-failure \
        --net=host \
        --privileged \
        -v /dev/net:/dev/net \
        typhoon1986/flannel:${FLANNEL_VERSION} \
        /opt/bin/flanneld \
            --ip-masq="${FLANNEL_IPMASQ}" \
            --etcd-endpoints=http://${MASTER_IP}:4001 \
            --iface="${FLANNEL_IFACE}")

    sleep 10
}

config_docker_network() {
    # Copy flannel env out and source it on the host
    flannelCID=$(docker -H ${FLANNEL_DOCKER_SOCK} ps | grep flannel | grep -v grep | awk '{print $1}')
    docker -H $FLANNEL_DOCKER_SOCK \
        cp ${flannelCID}:/run/flannel/subnet.env .
    source subnet.env

    # Configure docker net settings, then restart it
    case "${lsb_dist}" in
        coreos)
            DOCKER_CONF="/run/flannel_docker_opts.env"
            echo "DOCKER_OPTS=\"--selinux-enabled=false\"" | tee -a ${DOCKER_CONF}
            if [ "$BOOTSTRAP_FLANNEL" == "true" ]; then
              # delete lines if exists
              sed -i "/DOCKER_OPT_BIP.*/d" $DOCKER_CONF
              sed -i "/DOCKER_OPT_MTU.*/d" $DOCKER_CONF
              # use env file to setup docker daemon
              echo "DOCKER_OPT_BIP=\"--bip=${FLANNEL_SUBNET}\"" | tee -a ${DOCKER_CONF}
              echo "DOCKER_OPT_MTU=\"--mtu=${FLANNEL_MTU}\"" | tee -a ${DOCKER_CONF}
            fi
            ifconfig docker0 down
            brctl delbr docker0 && systemctl restart docker
            ;;
        centos)
            # FIXME: use EnvironmentFile, why centos systemd not work?
            # use systemd drop in instead of /etc/sysconfig/docker
            DOCKER_CONF="/etc/systemd/system/docker.service.d/docker.conf"
            if [ ! -f $DOCKER_CONF ]; then
              mkdir -p /etc/systemd/system/docker.service.d
            fi
            systemctl stop docker
            echo "[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --mtu=${FLANNEL_MTU} --bip=${FLANNEL_SUBNET}" | tee -a $DOCKER_CONF
            #echo "OPTIONS=\"\$OPTIONS --mtu=${FLANNEL_MTU} --bip=${FLANNEL_SUBNET}\"" | tee -a ${DOCKER_CONF}
            if ! command_exists ifconfig; then
                yum -y -q install net-tools
            fi
            ifconfig docker0 down
            yum -y -q install bridge-utils && brctl delbr docker0 && systemctl restart docker
            ;;
        amzn)
            DOCKER_CONF="/etc/sysconfig/docker"
            echo "OPTIONS=\"\$OPTIONS --mtu=${FLANNEL_MTU} --bip=${FLANNEL_SUBNET}\"" | tee -a ${DOCKER_CONF}
            ifconfig docker0 down
            yum -y -q install bridge-utils && brctl delbr docker0 && service docker restart
            ;;
        ubuntu|debian) # TODO: today ubuntu uses systemd. Handle that too
            DOCKER_CONF="/etc/default/docker"
            echo "DOCKER_OPTS=\"\$DOCKER_OPTS --mtu=${FLANNEL_MTU} --bip=${FLANNEL_SUBNET}\"" | tee -a ${DOCKER_CONF}
            ifconfig docker0 down
            apt-get install bridge-utils
            brctl delbr docker0
            service docker stop
            while [ `ps aux | grep /usr/bin/docker | grep -v grep | wc -l` -gt 0 ]; do
                echo "Waiting for docker to terminate"
                sleep 1
            done
            service docker start
            ;;
        *)
            echo "Unsupported operations system ${lsb_dist}"
            exit 1
            ;;
    esac

    # sleep a little bit
    sleep 5
}

start_kubelet() {
    # Start kubelet & proxy in container
    # TODO: Use secure port for communication
    docker run \
        --net=host \
        --pid=host \
        --privileged \
        --restart=on-failure \
        -d \
        -v /sys:/sys:ro \
        -v /var/run:/var/run:rw  \
        -v /:/rootfs:ro \
        -v /var/lib/docker/:/var/lib/docker:rw \
        -v /var/lib/kubelet/:/var/lib/kubelet:rw \
        typhoon1986/hyperkube-${ARCH}:v${K8S_VERSION} \
        /hyperkube kubelet \
            --pod_infra_container_image="typhoon1986/pause:2.0" \
            --allow-privileged=true \
            --api-servers=http://${MASTER_IP}:8080 \
            --address=0.0.0.0 \
            --enable-server \
            --cluster-dns=10.0.0.10 \
            --cluster-domain=cluster.local \
            --containerized \
            --v=2

    docker run \
        -d \
        --net=host \
        --privileged \
        --restart=on-failure \
        typhoon1986/hyperkube-${ARCH}:v${K8S_VERSION} \
        /hyperkube proxy \
            --master=http://${MASTER_IP}:8080 \
            --v=2
}

echo "Detecting your OS distro ..."
detect_lsb

if [ "$BOOTSTRAP_FLANNEL" == "true" ]; then
  echo "Starting bootstrap docker ..."
  bootstrap_daemon

  echo "start flannel service within bootstrap docker ..."
  start_flannel
fi

echo "config docker network to work with flannel ..."
config_docker_network

echo "start kublet service ..."
start_kubelet

echo "Worker done!"
