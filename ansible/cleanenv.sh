#!/bin/bash
rm roles/workstation/files/*.pem
rm roles/workstation/files/*.csr
rm roles/controller/files/*.*
rm roles/worker/files/*.*
rm roles/workstation/templates/encryption-config.yaml
