# Kubernetes The Easy Way (Part 2)


> Based on Kelsey Hightower's popular <a href="https://github.com/kelseyhightower/kubernetes-the-hard-way">Kubernetes The Hard Way</a> project (updated on August 31, 2017!)

Kubernetes The Hard Way is a fun project, created by Kelsey Hightower (of Google), which walks a user through each of the many manual steps to stand up a basic Kubernetes cluster on Google Compute Platform. I performed the steps manually at least three times before embarking on automating the steps using Terraform and Ansible.

## Dependencies

* [cfssl and cfssljson](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md)
* [kubectl](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md)
* [Google Cloud SDK](https://cloud.google.com/sdk/gcloud/)
* [Terraform](http://www.terraform.io)
* [Ansible](https://github.com/ansible/ansible)

## Terraform / Google Cloud Platform infrastructure

> You will execute the `terraform` binary from within the `terraform/` directory (also known as a "root module" in Terraform parlance).

In order to SSH to your compute nodes (for inspection / troubleshooting purposes) you must populate the following variables in the `terraform/terraform.tfvars` file. You just need to specify the user account you will use for SSH access and its associated public key. If you want to create a new SSH key, look up the `ssh-keygen` command.

You will notice these variables are referenced in the `terraform/main.tf` module in the google_compute_instance resources. Terraform will automatically create the user in the compute instance and add the public key to the `~/.ssh/authorized_keys` file for you.

* __gce_ssh_user__ (e.g. root or centos)
* __gce_ssh_public_key_file__ (e.g. ~/.ssh/id_rsa.pub)

In order for Terraform to authenticate to GCP, you must create a service account (I suggest calling it `terraform`) in the Google Cloud IAM console. Create a key for the service account and download it in JSON format. Save this file as `terraform/secrets/account.json` (overwrite the existing, placeholder file).

You can confirm proper functionality by executing `terraform plan` from the `terraform/` (root module) folder. The output should say `Plan: 18 to add, 0 to change, 0 to destroy.`.

## Ansible

> You will execute the `ansible-playbook` binary from within the `ansible/` folder.

### Dynamic Inventory

The Ansible playbook uses a <a href="https://github.com/ansible/ansible/tree/devel/contrib/inventory">GCE dynamic inventory script</a> which obviates the need to manage a static inventory. If you look at the `terraform/main.tf` module, at the `google_compute_instance` resources, you will see a `tag` key with assigned tags. The Ansible dynamic inventory leverages these tags to target controller and worker nodes.

You must configure the `ansible/inventory/gce.ini` file for your project, as follows:

  * __Line 44__: GCE service account e-mail address
  * __Line 45__: GCE service account private key file (in PEM format)
    + Line 24 shows how to create a PEM file using the PKCS12 file you can download from Google's IAM console. Basically, you just need to run `openssl pkcs12 -in <path to .p12 file> -passin pass:notasecret -nodes -nocerts | openssl rsa -out <path to output .pem file>`.
  * __Line 46__: GCE Project ID
  * __Line 47__: GCE Zone

### Running the playbook

Simply executing `ansible-playbook site.yml -i inventory/` from within the `ansible/` folder will execute the playbook, which configures your local workstation (for kubectl), and installs the controller (etcd, K8s API server, scheduler, and controller-manager) and worker (kubelet and kube-proxy) components.

The Ansible playbook is broken out into three roles - workstation, controller, and worker.

#### Workstation Role

* Create SSL certificates and keys (for CA, admin, workers, kube-proxy, and Kubernetes server)
* Create encryption key for managing secrets in Kubernetes
* Create kubeconfig file for local kubectl usage

#### Controller Role

* Distribute SSL certificates and keys to controller nodes
* Distribute encryption YAML file to controller nodes
* Install etcd on controller nodes
* Install Kubernetes control plane (API server, scheduler, and controller-manager services)

#### Worker Role

* Distribute SSL certificates and keys to worker nodes
* Distribute kube-proxy and kubeconfig files to worker nodes
* Install worker components (cri-o, kubelet, and kube-proxy services)

## Validation

The Ansible playbook should complete successfully, and have output similar to the following. Also, the playbook was written to be idempotent, so running it additional times should not change anything.

```
PLAY RECAP **************************************************************************
controller-0               : ok=7    changed=4    unreachable=0    failed=0
controller-1               : ok=7    changed=4    unreachable=0    failed=0
controller-2               : ok=7    changed=4    unreachable=0    failed=0
localhost                  : ok=33   changed=15   unreachable=0    failed=0
worker-0                   : ok=5    changed=3    unreachable=0    failed=0
worker-1                   : ok=5    changed=3    unreachable=0    failed=0
worker-2                   : ok=5    changed=3    unreachable=0    failed=0
```

You can validate connectivity to your Kubernetes cluster by running the `kubectl get nodes` command. You should see output similar to the following.

```
NAME       STATUS    AGE       VERSION
worker-0   Ready     2m        v1.7.4
worker-1   Ready     2m        v1.7.4
worker-2   Ready     2m        v1.7.4
```

## Clean Up

When you are ready to tear down your Kubernetes cluster, you simply need to run `terraform destroy` from within the `terraform/` folder and type "yes" to confirm.

I have also included a file called `ansible/cleanenv.sh` which will remove the files that get created by the Ansible playbook (e.g. SSL certificates and keys, kubeconfig files, etc.)

## To Do

* Add variables for cluster name and etc, kubernetes component versions
* Investigate and fix TF compute_route error on initial run (requires a second terraform apply)
