## Build and Deploy a Modern YouTube Clone Application in React JS with Material UI 5

```sh
git clone 

terraform init
terraform plan
terraform apply -auto-approve

```
## Install AWS cli
```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
aws --version
```
## Install kubectl on jenkins
```sh
sudo apt update
sudo apt install curl -y
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```
## Install eksctl on jenkins

```sh
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
cd /tmp
sudo mv /tmp/eksctl /bin
eksctl version
```
## Setup kubernetes cluster with eksctl

```sh
eksctl create cluster --name youtube-cluster \
--region ap-southeast-1 \
--node-type t2.small \
--nodes 3

##update config
aws eks update-kubeconfig --name youtube-cluster --region ap-southeast-1

#Verify Cluster with below command
kubectl get nodes
kubectl get svc
```