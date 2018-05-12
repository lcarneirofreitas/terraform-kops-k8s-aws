# Terraform And Kops Kubernetes Aws

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

- create s3 buckets
```
aws --region=us-east-1 s3api create-bucket --bucket kubernetes-state-collystore
aws --region=us-east-1 s3api create-bucket --bucket terraform-state-collystore
```

- show s3 buckets
```
aws s3 ls
```

- versioning amazon s3
```
aws --region=us-east-1 s3api put-bucket-versioning --bucket kubernetes-state-collystore --versioning-configuration Status=Enabled
aws --region=us-east-1 s3api put-bucket-versioning --bucket terraform-state-collystore --versioning-configuration Status=Enabled
```

- export s3 bucket to kops
```
export KOPS_STATE_STORE=s3://kubernetes-state-collystore
```

- configure dns route53 amazon
```
ID=$(uuidgen) && \
aws route53 create-hosted-zone \
--name collystore.com.br \
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

- create cluster kubernetes kops
```
kops create cluster \
    --name collystore.com.br \
    --node-count 2 \
    --zones us-east-1a,us-east-1b,us-east-1c \
    --master-zones us-east-1a,us-east-1b,us-east-1c \
    --node-size t2.micro \
    --master-size m4.large \
    --dns-zone collystore.com.br \
    --state s3://kubernetes-state-collystore \
    --topology private \
    --networking weave \
    --bastion=true \
    --vpc $VCP \
    --yes
```

- validating cluster kubernetes
```
kops validate cluster --state s3://kubernetes-state-collystore --name collystore.com.br

kubectl get nodes -o wide

ssh admin@bastion.collystore.com.br

kubectl -n kube-system get pod
```

- copy key to access the other servers in the cluster
```
scp -pvr /home/user/.ssh/id_rsa admin@bastion.collystore.com.br:/home/admin/.ssh/
```

- install web interface dashboard kubernetes kops
```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
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
https://api.collystore.com.br/ui/

# Tests Kubernetes

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
kubectl describe services | grep -w "LoadBalancer Ingress"
```

- validade access to application
```
watch -n1 "curl -s $(kubectl describe services | grep -w "LoadBalancer Ingress" | awk '{print $3}')"
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
kubectl get deployment apache-prod-deployment -o yaml > apache-prod-deployment.yaml
```

- update nodes cluster kubernetes kops

https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md
```
kops edit ig nodes

kops update cluster collystore.com.br --yes

kops rolling-update cluster

kops get ig
Using cluster from kubectl context: collystore.com.br

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


- delete cluster kubernetes
```
kops delete cluster --state=s3://kubernetes-state-collystore collystore.com.br --yes
```

- delete networks terraform
```
terraform destroy

```

- References

https://aws.amazon.com/blogs/compute/kubernetes-clusters-aws-kops/

https://ryaneschinger.com/blog/kubernetes-aws-vpc-kops-terraform/

https://github.com/kubernetes/kops/blob/master/docs/aws.md#configure-dns

https://kubecloud.io/setting-up-a-highly-available-kubernetes-cluster-with-private-networking-on-aws-using-kops-65f7a94782ef

https://www.youtube.com/watch?v=IImQrJWbaDo

https://medium.com/cloud-academy-inc/setup-kubernetes-on-aws-using-kops-877f02d12fc1

http://rundeck.org/docs/administration/setting-up-an-rdb-datasource.html

https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2


