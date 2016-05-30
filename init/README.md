# 使用Vagrant部署CoreOS并安装一个kubernetes集群
## 启动CoreOS的单机节点
CoreOS的启动说明参考：https://coreos.com/os/docs/latest/booting-on-vagrant.html
使用vagrant启动一个CoreOS的机器：

```
git clone https://github.com/coreos/coreos-vagrant.git
cd coreos-vagrant
```
将config.rb.sample和user-data.sample都拷贝出来并修改配置(user-data是cloud-config的格式的配置)。因为实际k8s也要使用flannel，顺便把etcd和flannel也部署了。使用的user-data配置如下：

```
#cloud-config

---
coreos:
  etcd2:
    discovery: https://discovery.etcd.io/d66ea77025738bc9ed168e30c8b19f29
    advertise-client-urls: http://$public_ipv4:2379
    initial-advertise-peer-urls: http://$private_ipv4:2380
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380,http://$private_ipv4:7001
  fleet:
    public-ip: $public_ipv4
  flannel:
    interface: $public_ipv4
  units:
  - name: etcd2.service
    command: start
  - name: fleet.service
    command: start
  - name: flanneld.service
    drop-ins:
    - name: 50-network-config.conf
      content: |
        [Service]
        ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
    command: start
```

然后执行vagrant up
等待启动后，执行vagrant ssh core-01登陆到机器上。上面会启动2个docker daemon进程：/var/run/early-docker.sock和/var/run/docker.sock。flannel会启动到early-docker.sock下（特权模式）
可以用如下命令，查看flannel的启动日志：

```
docker -H unix:///var/run/early-docker.sock ps
docker -H unix:///var/run/early-docker.sock logs [your flannel container name]
```

## 部署kubernetes
先编辑/etc/hosts文件，可以通过hostname访问到每个机器，比如：

```
172.17.8.101 core-01
```

执行下面的命令完成初始化

```
git clone https://github.com/k8sp/hadoop.git
cd hadoop/init
sudo su
```

修改env.sh，设置对应的参数。

| 参数 | 说明 |
| ----- | -----|
|FLANNEL_IFACE|flannel节点之间通信的网卡，在vagrant环境下需要绑定eth1，而不是eth0|
|MASTER_IP|k8s中master节点的IP，并且是外网可访问的IP|

如果已经使用了coreos cloud-config启动了etcd和flannel，就可以无需使用本脚本启动。
如果要使用本脚本启动etcd和flannel，需要修改：```#export BOOTSTRAP_FLANNEL=false``` 为 
```export BOOTSTRAP_FLANNEL=true```

```
#!/bin/bash
# add proxy below to enable proxies
#export HTTP_PROXY=<http://PROXYHOST:PORT>
#export HTTPS_PROXY=<https://PROXYHOST:PORT>
#export KUBERNETES_HTTP_PROXY=<http://PROXYHOST:PORT>
#export KUBERNETES_HTTPS_PROXY=<https://PROXYHOST:PORT>

export MASTER_IP=172.17.8.101

export K8S_VERSION=1.2.0
export ETCD_VERSION=2.2.1
export FLANNEL_VERSION=0.5.5
export FLANNEL_IFACE=eth0
export FLANNEL_IPMASQ=true
# uncomment this to enable start a bootstrap docker daemon at /var/run/bootstrap-docker.sock
# and start flannel under it
#export BOOTSTRAP_FLANNEL=false
FLANNEL_DOCKER_SOCK=/var/run/early-docker.sock
#FLANNEL_DOCKER_SOCK=/var/run/docker-bootstrap.sock
```

下面是不使用coreos的cloud-config启动etcd和flannel的配置：

```
#cloud-config

---
coreos:
  fleet:
    public-ip: $public_ipv4
  units:
  - name: fleet.service
    command: start
```

如果是在CoreOS上，检查/run/flannel_docker_opts.env是否正确，检查flannel服务正常运行
然后执行：

```
. ./env.sh
./master.sh
```
等待启动完成，之后可以查看如果hyperkube kublet进程和对应的proxy, apiserver, master启动完成

```
docker ps
```

