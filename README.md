# Kubernetes The Easy Way (Part 2)


> Based on Kelsey Hightower's (of Google) <a href="https://github.com/kelseyhightower/kubernetes-the-hard-way">Kubernetes The Hard Way</a> (updated on August 31, 2017!)

Kubernetes The Hard Way is a fun project, created by Kelsey Hightower (of Google), which walks a user through each of the many manual steps to stand up a basic Kubernetes cluster on Google Compute Platform. I performed the steps manually at least three times before embarking on automating the steps using Terraform and Ansible.

## Dependencies

* [cfssl and cfssljson](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md)
* [kubectl](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md)
* [Google Cloud SDK](https://cloud.google.com/sdk/gcloud/)
* [Terraform](http://www.terraform.io)
* [Ansible](https://github.com/ansible/ansible)

## Terraform / Google Cloud Platform infrastructure

> You will execute the `terraform` binary from within the `terraform` directory (also known as a "root module" in Terraform parlance).

In order to SSH to your compute nodes (for inspection / troubleshooting) you must populate the `terraform/terraform.tfvars` file `gce_ssh_user` and `gce_ssh_public_key_file` variables (point to your public key file).

You must create a `secrets/account.json` file. First, you must create a service account (call it `terraform`) in the Google Cloud IAM console, and then you can create the associated JSON file which includes your project ID and private key.

You can confirm proper functionality by executing `terraform plan` from the terraform (root module) folder. The output should say `Plan: 18 to add, 0 to change, 0 to destroy.`.

## Ansible

> You will execute the `ansible-playbook` binary from within the `ansible` folder.

Simply executing `ansible-playbook site.yml -i inventory` from within the `ansible` folder will execute the playbook, which configures your local workstation (for kubectl), and installs the controller (etcd, K8s API server, scheduler, and controller-manager) and worker (kubelet and kube-proxy) components.

The Ansible playbook is broken out into three roles - workstation, controller, and worker.

#### Dynamic Inventory

This Ansible playbook uses a <a href="https://github.com/ansible/ansible/tree/devel/contrib/inventory">GCE dynamic inventory script</a> which obviates the need to manage a static inventory. You will need to create a folder called `inventory/` which contains both the `gce.py` and `gce.ini` files.

You must configure the `gce.ini` file for your project, as follows:

* gce.ini

  + _Line 44_: GCE service account e-mail address
  + _Line 45_: GCE service account private key file (in PEM format)
    - Line 24 shows how to create a PEM file using the PKCS12 file you can download from Google's IAM console. Basically, you just need to run `openssl pkcs12 -in <path to .p12 file> -passin pass:notasecret -nodes -nocerts | openssl rsa -out <path to output .pem file>`.
  + _Line 46_: GCE Project ID
  + _Line 47_: GCE Zone
