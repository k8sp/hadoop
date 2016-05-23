#!/bin/bash
#kubectl --namespace=kube-system create secret docker-registry bfdreg --docker-server=https://docker.baifendian.com --docker-username=sys --docker-password=DwHMmvAF --docker-email=yi.wu@baifendian.com
kubectl create secret docker-registry bfdreg --docker-server=https://docker.baifendian.com/v1/ --docker-username=sys --docker-password=DwHMmvAF --docker-email=yi.wu@baifendian.com
