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
. ./env.sh
```
如果是在CoreOS上，检查/run/flannel_docker_opts.env是否正确，检查flannel服务正常运行
然后执行：
```
./master.sh
```
等待启动完成，之后可以查看如果hyperkube kublet进程和对应的proxy, apiserver, master启动完成
```
docker ps
```

