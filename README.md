## Hadoop Example

* ResourceManager and NodeManager will be running with docker on k8s.
* HDFS is used for test, now it is running in docker with single node mode.

## Cluster init
Checkout: (init/README.md)

## Usage

### step0 Prerequisites

* Installed kubenetes cluster (or single node).
* kubectl command line tool.
	
### step1 Deploy HDFS

```
	kubectl create -f hadoop/hadoop-hdfs-rc.yaml
	kubectl create -f hadoop/hadoop-hdfs-svc.yaml
		
```

### step2 Deploy Zookeeper

```
	kubectl create -f hadoop/zookeeper-rc.yaml
	kubectl create -f hadoop/zookeeper-svc.yaml
```

### step2 Deploy Hadoop ResourceManager

* Get HDFS service IP 

```
yancey@ yancey-macbook hadoop$kubectl get svc
NAME            CLUSTER-IP   EXTERNAL-IP   PORT(S)                                                 AGE
hadoop-hdfs     10.0.0.114   <none>        9000/TCP,50070/TCP                                      50m
hadoop-master   10.0.0.246   <none>        8088/TCP,8033/TCP,8032/TCP,8031/TCP,8030/TCP,8090/TCP   3d
kubernetes      10.0.0.1     <none>        443/TCP                                                 7d
zookeeper       10.0.0.70    <none>        2181/TCP                                                2d
```
* Generate hadoop-master-rc.yaml from hadoop-master-rc.yaml.default

```
sed "s/<ZOOKEEPER_ADDR>/10.0.0.70:2181/g" hadoop-master-rc.yaml.default | sed "s/<HDFS_HOST>/10.0.0.114/g" > hadoop-master-rc.yaml

```
* Create hadoop-master pod and service.

```
kubectl create -f hadoop/hadoop-master-rc.yaml
kubectl create -f hadoop/hadoop-master-svc.yaml
```

### step3 Deploy Hadoop NodeManager
* Generate hadoop-slave-rc.yaml from hadoop-slave-rc.yaml.default

```
sed "s/<RM_HOSTNAME>/10.0.0.246/g" hadoop-slave-rc.yaml.default | sed "s/<HDFS_HOST>/10.0.0.114/g" > hadoop-slave-rc.yaml
```

* Create hadoop node manager pod

```
kubectl create -f hadoop/hadoop-slave-rc.yaml
``` 

* append hadoop-slave hostname to the /etc/hosts on hadoop master pod.

```
yancey@ yancey-macbook hadoop$kubectl get pods
NAME                        READY     STATUS    RESTARTS   AGE
hadoop-hdfs-hay0j           1/1       Running   0          19h
hadoop-master-ir8sl         1/1       Running   0          4h
hadoop-slave-yxgt5          1/1       Running   0          4h

kubectl exec -it hadoop-master-ir8sl /bin/bash
root@hadoop-master-ir8sl:/opt/hadoops#echo "10.1.99.2       hadoop-slave-yxgt5" >> /etc/hosts
```

### step4 Run a MR job

* Exec to hadoop-master pod

```
root@hlg-2p29-yanxu:~# kubectl exec -it hadoop-master-ir8sl /bin/bash
```

* Run a mapreduce job


```
root@hadoop-master-ir8sl:/opt/hadoops# pwd
/opt/hadoops
root@hadoop-master-ir8sl:/opt/hadoops# sh run_wordcount.sh
```
* Resource Manager web

	You can open resource manager web with the address of the node address which hadoop-master pod running. like:
	
	*http://{hadoop-master-node}:18088/cluster/apps*
