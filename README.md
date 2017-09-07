# Kubernetes The Easy Way (Part 2)


Based on Kelsey Hightower's (of Google) <a href="https://github.com/kelseyhightower/kubernetes-the-hard-way">Kubernetes The Hard Way</a> (updated on August 31, 2017!)

Kubernetes The Hard Way is a fun project, created by Kelsey Hightower (of Google), which walks a user through each of the many manual steps to stand up a basic Kubernetes cluster on Google Compute Platform. I performed the steps manually at least three times before embarking on automating the steps using Terraform and Ansible.

## Dependencies

* [Terraform](http://www.terraform.io)
* [Ansible](https://github.com/ansible/ansible)
* [Google Cloud SDK](https://cloud.google.com/sdk/gcloud/)

## Terraform / Google Cloud Platform infrastructure Details

In order to SSH to your compute nodes (for inspection / troubleshooting) you must populate the `terraform/terraform.tfvars` file `gce_ssh_user` and `gce_ssh_public_key_file` variables (point to your public key file).

You must create a `secrets/account.json` file. First, you must create a service account (call it `terraform`) in the Google Cloud IAM console, and then you can create the associated JSON file which includes your project ID and private key.

You can confirm proper functionality by executing `terraform plan` from the terraform (root module) folder. It should say `18 Resources to Add`.

## Ansible Details
