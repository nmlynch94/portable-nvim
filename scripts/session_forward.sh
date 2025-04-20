#!/bin/sh

set -eua pipefail

AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}

EKS_CLUSTER="$(aws eks list-clusters | jq '.clusters[0]' -r)"
EC2_BASTION_ID="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*private-bastion*" --query "Reservations[].Instances[].InstanceId" --output text)"
EKS_CLUSTER_URL=$(
  aws eks describe-cluster --name "$EKS_CLUSTER" --query "cluster.endpoint" --output text
)
EKS_CLUSTER_URL_NO_PROTOCOL="${EKS_CLUSTER_URL#https://}"

HOSTS_FILE_ENTRY="127.0.0.1 localhost $EKS_CLUSTER_URL_NO_PROTOCOL"

# If the hosts file entry doesn't exist, place it in
grep -qxF "$HOSTS_FILE_ENTRY" /etc/hosts || echo "$HOSTS_FILE_ENTRY" | sudo tee -a /etc/hosts >/dev/null

# Update kubeconfig
aws eks update-kubeconfig --name "$EKS_CLUSTER"

# Start ssm port forwarding session
while true; do
  aws ssm start-session --target "$EC2_BASTION_ID" --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{"portNumber":["443"],"localPortNumber":["8443"],"host":['"\"$EKS_CLUSTER_URL_NO_PROTOCOL\""']}'
done
