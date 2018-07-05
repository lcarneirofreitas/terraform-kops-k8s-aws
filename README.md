# Terraform + Kops + Kubernetes Aws


- Infraestructure as code and kubernetes concepts

https://pt.slideshare.net/LeandroFreitas29/terraform-kops-kubernetes-na-aws


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

- change domain k8s backend.tf file
```
sed -i "s#domain_k8s#`echo $DOMAIN_K8S`#g" terraform/backend.tf
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
scp -pvr /home/$(whoami)/.ssh/id_rsa admin@bastion.$DOMAIN_K8S:/home/admin/.ssh/

ssh admin@bastion.$DOMAIN_K8S
```

- install web interface dashboard kubernetes kops
```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

- granting admin privileges to Dashboard's Service Account ()

https://github.com/kubernetes/dashboard/wiki/Access-control

```
kubectl create -f kubernetes/helpers/admin/dashboard-admin.yaml
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

