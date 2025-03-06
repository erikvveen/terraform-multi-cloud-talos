# Terraform-multi-cloud-talos

This module simply kicks off the clusters defined in the variable "clusters" in locals.tf.

It supports AWS and Linode as Cloud Platform.

Before downloading this code and executing it simply with a "terraform init" and "terraform apply", please make sure that you have set your AWS and Linode credentials.

In this testing phase the script assumes you need both credentials for AWS and Linode. 
If you have only one credentials for one platform I suggest you simply gray out the module you do not have the credentials for (Linode or AWS).

Your credentials can be set by creating an env variable: TF_VAR_linode_token=<your token> and e.g. running "aws sso login --profile <your profile>

The code in "clusters.tf" kicks off the clusters with Cilium as CNI.

The ISTIO installation is done using helm, BUT...

I did not succeed in finding a way to define dynamically multiple k8s and helm provider blocks referring to the respective clusters. 
Root cause is that provider blocks should be defined in (this) root module and may not be defined in "lower" modules. Terraform does not support the dynamic creation of provider blocks.
If you want to make friends for life, please let me know how to do this.

Due to the limitation of Terraform to not support dynamic provider blocks I chose that for testing purposes its for now good enough to work with ugly separate "addon-" files.

The "addon" files can only be use mutual-exclusive and represent a specific test set up.

"addon-standard-sidecar.tf" represents a setup that implements ISTIO with a sidecare setup. An "echoserver" pod is kicked off with an "echoserver" service that uses the k8s Gateway pattern to expose to an automatically created Loadbancer-ip at port 5005 a simple index.html file. 

Correct functioning of the setup can be tested by taking the ip address of the "echoserver" service (shown by kubectl get services -A) and do a "wget <Loadbalancer-ip-address>:5005". A index.html should be downloaded.

