#!/bin/bash

# Move explicitly into the working directory containing your Terraform configs
cd /home/lyn-reinogar/azure-vm-audit

# Ensure the system PATH includes directories for terraform, az cli, and python3
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Execute the runtime orchestration stream via inline variables
ARM_CLIENT_ID="5f483c6d-9b12-4217-bc8a-d790f1354e6b" \
ARM_CLIENT_SECRET="3xP8Q~vR_M.kZL4W2hGnYjTfAsBcDeFgHiJkL" \
ARM_TENANT_ID="e109d3b4-8c76-4a52-9f13-6b74e201d85a" \
AZURE_CLIENT_ID="5f483c6d-9b12-4217-bc8a-d790f1354e6b" \
AZURE_CLIENT_SECRET="3xP8Q~vR_M.kZL4W2hGnYjTfAsBcDeFgHiJkL" \
AZURE_TENANT_ID="e109d3b4-8c76-4a52-9f13-6b74e201d85a" \
TF_VAR_nexus_user="lyn-reinogar" \
TF_VAR_nexus_pass="7JquIANDESjbXPEthaWSS6yZY9wBhwLRwMFnLaaq" \
terraform apply -auto-approve -var="azure_subscription_id=3b8a1c9e-5f6d-472a-9e1b-8c3d4f5a6b7c" >> audit_cron.log 2>&1

# TRIGGER USER-SPACE LOGROTATE IMMEDIATELY AFTER TERRAFORM
# -s specifies a local status file so it runs without sudo privileges
logrotate -s /home/lyn-reinogar/azure-vm-audit/logrotate.status /home/lyn-reinogar/azure-vm-audit/logrotate.conf
EOF