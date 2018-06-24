# Terraform + Kops + Kubernetes Aws

- install terraform
```
curl -LO https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
unzip terraform_0.11.7_linux_amd64.zip
chmod +x terraform_0.11.7_linux_amd64
sudo mv terraform_0.11.7_linux_amd64 /usr/local/bin/terraform
```

- install kops
```
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops
```

- install kubectl
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

- install awscli
```
pip install awscli
```

- save aws credentials to run awscli
```
cat .aws/credentials
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
output = text
```

- export domain name
```
export DOMAIN_K8S="DOMAIN NAME HERE"
echo $DOMAIN_K8S
```

- create s3 buckets
```
aws --region=us-east-1 s3api create-bucket --bucket kubernetes-state-$DOMAIN_K8S
aws --region=us-east-1 s3api create-bucket --bucket terraform-state-$DOMAIN_K8S
```

- show s3 buckets
```
aws s3 ls
```

- versioning amazon s3
```
aws --region=us-east-1 s3api put-bucket-versioning --bucket kubernetes-state-$DOMAIN_K8S --versioning-configuration Status=Enabled
aws --region=us-east-1 s3api put-bucket-versioning --bucket terraform-state-$DOMAIN_K8S --versioning-configuration Status=Enabled
```

- export s3 bucket to kops
```
export KOPS_STATE_STORE=s3://kubernetes-state-$DOMAIN_K8S
echo $KOPS_STATE_STORE
```

- configure dns route53 amazon
```
ID=$(uuidgen) && \
aws route53 create-hosted-zone \
--name $DOMAIN_K8S \
--caller-reference $ID
```

- running terraform plan and apply
```
cd terraform && \
terraform init

Initializing the backend...
region
  The region of the S3 bucket.

  Enter a value: us-east-1
```

```
terraform plan

terraform apply
```

- create cluster kubernetes kops (get the result of the previous command and feed the $VPC variable)
```
kops create cluster \
    --name $DOMAIN_K8S \
    --node-count 2 \
    --zones us-east-1a,us-east-1b,us-east-1c \
    --master-zones us-east-1a,us-east-1b,us-east-1c \
    --node-size t2.micro \
    --master-size m4.large \
    --dns-zone $DOMAIN_K8S \
    --state s3://kubernetes-state-$DOMAIN_K8S \
    --topology private \
    --networking weave \
    --bastion=true \
    --vpc $VCP \
    --yes
```

- validating cluster kubernetes
```
kops validate cluster --state s3://kubernetes-state-$DOMAIN_K8S --name $DOMAIN_K8S

kubectl get nodes -o wide

kubectl -n kube-system get pod
```

- validating context kubernetes aws
```
view ~/.kube/config
```

- copy key to access the other servers in the cluster
```
scp -pvr /home/user/.ssh/id_rsa admin@bastion.$DOMAIN_K8S:/home/admin/.ssh/

ssh admin@bastion.$DOMAIN_K8S
```

- install web interface dashboard kubernetes kops
```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

- granting admin privileges to Dashboard's Service Account ()

https://github.com/kubernetes/dashboard/wiki/Access-control

```
kubectl create -f kubernetes/helpers/dashboard-admin.yaml
```

- access 1
```
kubectl proxy
```
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

- access 2
```
kubectl config view --minify
```
https://api.$DOMAIN_K8S/ui/

# Tests App1 Kubernetes

- create pod server apache + php
```
cd kubernetes
kubectl create -f app1/prod/deployment.json
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
kubectl create -f app1/prod/loadbalancer.json
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
kubectl scale --replicas=3 -f app1/prod/deployment.json
watch -n1 'kubectl get pod -o wide'
```

- change image deploy
```
sed -i 's#lcarneirofreitas/image_test_apachephp:0.3#lcarneirofreitas/image_test_apachephp:0.2#g' app1/prod/deployment.json
kubectl apply -f app1/prod/deployment.json
watch -n1 'kubectl get pod -o wide'
```

```
sed -i 's#lcarneirofreitas/image_test_apachephp:0.2#lcarneirofreitas/image_test_apachephp:0.3#g' app1/prod/deployment.json
kubectl apply -f app1/prod/deployment.json
watch -n1 'kubectl get pod -o wide'
```

- deploy with problems
```
sed -i 's#lcarneirofreitas/image_test_apachephp:0.3#lcarneirofreitas/image_test_apachephp:0.7#g' app1/prod/deployment.json
kubectl apply -f app1/prod/deployment.json
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

kubectl create -f helpers/metrics-server/deploy/1.8+/

kubectl create -f helpers/heapster.yaml
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
kubectl delete -f app1/prod/deployment.json

kubectl delete -f app1/prod/loadbalancer.json

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

# Destroy Environment

- delete cluster kubernetes
```
kops delete cluster --state=s3://kubernetes-state-$DOMAIN_K8S $DOMAIN_K8S --yes
```

- delete networks terraform
```
terraform destroy

```

# References

https://aws.amazon.com/blogs/compute/kubernetes-clusters-aws-kops/

https://ryaneschinger.com/blog/kubernetes-aws-vpc-kops-terraform/

https://github.com/kubernetes/kops/blob/master/docs/aws.md#configure-dns

https://kubecloud.io/setting-up-a-highly-available-kubernetes-cluster-with-private-networking-on-aws-using-kops-65f7a94782ef

https://www.youtube.com/watch?v=IImQrJWbaDo

https://medium.com/cloud-academy-inc/setup-kubernetes-on-aws-using-kops-877f02d12fc1

http://rundeck.org/docs/administration/setting-up-an-rdb-datasource.html

https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2

https://github.com/kubernetes-incubator/metrics-server

