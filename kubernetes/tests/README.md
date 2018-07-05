# Tests App1 Kubernetes

- create pod server apache + php
```
cd kubernetes
kubectl create -f tests/app1/prod/deployment.json
```

- show new deployment
```
kubectl get deployment -o wide
```

- describe deployments
```
kubectl describe deployments
```

- create loadbalance to access application
```
kubectl create -f tests/app1/prod/loadbalancer.json
```

- show new service
```
kubectl get service -o wide
```

- discovery dns loadbalance to access application
```
kubectl describe services apache-prod-loadbalancer
```

- create dns entry for app1 associated with loadbalance address
```
sed -i "s#my-load-balance#$(kubectl describe services apache-prod-loadbalancer | grep 'LoadBalancer Ingress' | awk '{print $3}')#g" helpers/route53-app1.tf

mv helpers/route53-app1.tf terraform/
```

- apply change terraform
```
cd terraform

terraform plan

terraform apply 
```

- validade access to application
```
watch -n1 "curl -s http://app1.$DOMAIN_K8S"
```

- scale application apache + php
```
kubectl scale --replicas=3 -f tests/app1/prod/deployment.json
watch -n1 'kubectl get pod -o wide'
```

- change image deploy
```
sed -i 's#lcarneirofreitas/image_test_apachephp:0.3#lcarneirofreitas/image_test_apachephp:0.2#g' tests/app1/prod/deployment.json
kubectl apply -f tests/app1/prod/deployment.json
watch -n1 'kubectl get pod -o wide'
```

```
sed -i 's#lcarneirofreitas/image_test_apachephp:0.2#lcarneirofreitas/image_test_apachephp:0.3#g' tests/app1/prod/deployment.json
kubectl apply -f tests/app1/prod/deployment.json
watch -n1 'kubectl get pod -o wide'
```

- deploy with problems
```
sed -i 's#lcarneirofreitas/image_test_apachephp:0.3#lcarneirofreitas/image_test_apachephp:0.7#g' tests/app1/prod/deployment.json
kubectl apply -f tests/app1/prod/deployment.json
watch -n1 'kubectl get pod -o wide'
```

- get yaml deployment
```
kubectl get deployment apache-prod-deployment -o yaml > /tmp/apache-prod-deployment.yaml && cat /tmp/apache-prod-deployment.yaml
```

- tests horizontal pod autoscaling (metrics and influxdb)

https://github.com/kubernetes/heapster/blob/master/deploy/kube-config/influxdb/heapster.yaml
```
git clone git@github.com:kubernetes-incubator/metrics-server.git

kubectl create -f helpers/admin/metrics-server/deploy/1.8+/

kubectl create -f helpers/admin/heapster.yaml
```

- stress test example
```
kubectl autoscale deployment apache-prod-deployment --cpu-percent=50 --min=2 --max=10

ab -k -c 100 -n 200000 http://app1.$DOMAIN_K8S/

```

```
watch -n1 'kubectl get hpa'

watch -n1 'kubectl get pod'
```

- delete deployment and loadbalance
```
kubectl delete -f tests/app1/prod/deployment.json

kubectl delete -f tests/app1/prod/loadbalancer.json

kubectl get deployment

kubectl get service
```

# Tests App2 Kubernetes

- deploy rabbitmq
```
kubectl apply -f app2/prod/rabbit/k8s/rabbitmq-deployment.yaml
```

- deploy service rabbitmq
```
kubectl apply -f app2/prod/rabbit/k8s/rabbitmq-service.yaml
```

- deploy producer
```
kubectl apply -f app2/prod/rabbit/k8s/producer-deployment.yaml
```

- deploy consumer
```
kubectl apply -f app2/prod/rabbit/k8s/consumer-deployment.yaml
```

- access admin rabbitmq port-forward kubernetes
```
kubectl port-forward rabbitmq-67b94c7d77-l7xn2 15672:15672

Forwarding from 127.0.0.1:15672 -> 15672

user: guest
pass: guest
```

- get logs pod consumer or producer
```
kubectl logs -f producer-64b6945654-sw4xw
```

- remove consumer pod
```
kubectl scale deployment consumer --replicas=0
```

- add consumer pod
```
kubectl scale deployment consumer --replicas=1
```

- update version image pod
```
sed -i 's#lcarneirofreitas/consumer#lcarneirofreitas/consumer:v2#g' app2/prod/rabbit/k8s/consumer-deployment.yaml

kubectl apply -f app2/prod/rabbit/k8s/consumer-deployment.yaml

watch -n1 'kubectl get pod -o wide'
```

- delete deployment and loadbalance
```
kubectl delete -f app2/prod/rabbit/k8s/consumer-deployment.yaml

kubectl delete -f app2/prod/rabbit/k8s/producer-deployment.yaml

kubectl delete -f app2/prod/rabbit/k8s/rabbitmq-deployment.yaml

kubectl delete -f app2/prod/rabbit/k8s/rabbitmq-service.yaml 

kubectl get deployment

kubectl get service
```


# Tests autoscaling nodes kops

- update nodes cluster kubernetes kops

https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md
```
kops edit ig nodes --state=s3://kubernetes-state-$DOMAIN_K8S

kops update cluster $DOMAIN_K8S --state=s3://kubernetes-state-$DOMAIN_K8S --yes

kops rolling-update cluster --state=s3://kubernetes-state-$DOMAIN_K8S

kops get ig --state=s3://kubernetes-state-$DOMAIN_K8S

Using cluster from kubectl context: $DOMAIN_K8S

NAME			ROLE	MACHINETYPE	MIN	MAX	ZONES
bastions		Bastion	t2.micro	1	1	us-east-1a,us-east-1b,us-east-1c
master-us-east-1a	Master	m4.large	0	0	us-east-1a
master-us-east-1b	Master	m4.large	1	1	us-east-1b
master-us-east-1c	Master	m4.large	1	1	us-east-1c
nodes			Node	t2.micro	1	1	us-east-1a,us-east-1b,us-east-1c

watch -n1 'kubectl get nodes -o wide'

```

- destroy ec2 
```
aws --region=us-east-1 ec2 describe-instances --output json | grep -i instanceid

aws --region=us-east-1 ec2 terminate-instances --instance-ids $INSTANCE_ID

watch -n1 'kubectl get nodes -o wide'
```