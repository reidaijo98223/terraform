# Azure_VM_Audit

An automated utility that leverages Terraform, native Azure CLI, and curl to query, transform, and export live Virtual Machine (VM) operational status data directly to an enterprise Nexus repository.

## Directory Structure

For this automation engine to execute correctly, all core files must reside together within a single workspace directory on your Linux instance:

```text
~/azure-vm-audit/
├── main.tf              # Core Terraform orchestration and data query pipelines
├── variables.tf         # Input variable schemas and configurations
├── outputs.tf           # Post-apply terminal reporting blocks
└── run_azure_audit.sh   # Master shell orchestrator and user-space log rotation
```

## Workflow Execution Flow

```text
[Ansible Control Node Execution / Linux Cron Daemon]
           │
           ▼
[Trigger Master Shell Orchestrator] (Invokes `run_azure_audit.sh`)
           │
           ▼
[Inject Isolated Service Principal] ──► Sets inline environment credentials in-memory
           │
           ▼
[Initialize & Apply Terraform] (Runs dynamically with `-auto-approve`)
           │
           ▼
[Query Live Azure Infrastructures] ──► Native `az vm list` over HTTPS
           │
           ▼
[Compile Local Report Artifact]
           └─── azure_vms_inventory_status.csv  (Raw comma-delimited data payload)
           │
           ▼
[Export Telemetry Matrix Data] ──► Secure native `curl` PUT upload to central Nexus repository
           │
           ▼
[Sanitize Staging Filesystem] ──► Triggers `logrotate` to prevent storage bloat ──► [Done]
```

## Security Architecture (Credential Management)

To balance ease-of-use with enterprise-grade security compliance, **no separate credentials file is needed**. All critical access tokens are isolated directly within the `run_azure_audit.sh` script.

* **Environment Isolation:** The Service Principal strings (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`) and Nexus authorization parameters are injected purely as inline environment variables.
* **Zero-Disk Footprint:** Credentials live only in transient machine memory during the execution lifecycle. They are never committed to plain-text configuration files or written to the host directory disk.
* **Access Control:** The script is secured with strict file permissions to ensure that only the script owner can view or execute the file containing the tokens.

## 🛠️ Automated Setup & Execution

### 1. Enforce Cryptographic File Isolation
Run the following command immediately after deploying your script to ensure that no unauthorized users on the Linux VM can inspect your embedded Service Principal credentials:

```bash
chmod 700 ~/azure-vm-audit/run_azure_audit.sh
```

### 2. Configure Daily Crontab Automation
To automate this data aggregation pipeline to run completely headless every morning at **5:00 AM**, drop this rule directly into your local user cron configuration (`crontab -e`):

```text
0 5 * * * /home/YOUR_LINUX_USERNAME/azure-vm-audit/run_azure_audit.sh
```

### 3. Reviewing Logs
All execution logs, operational outputs, and script errors are dynamically captured and written to a rolling tracking file:
```bash
tail -f ~/azure-vm-audit/audit_cron.log
```
The script will automatically rotate this log file every 7 days using an unprivileged user-space `logrotate` command hook to prevent local VM disk bloat.

---

# Azure RHEL VM - Deployment

This repository contains **Terraform** infrastructure-as-code to deploy a fully configured Red Hat Enterprise Linux (RHEL) 9 Virtual Machine on Microsoft Azure. 

The virtual machine is customized for role-based access control (RBAC), provisioned with specialized user access, and includes pre-installed runtime dependencies.

## Infrastructure Specifications

* **Operating System:** Red Hat Enterprise Linux (RHEL) 9 (Official Gen2 Image)
* **Compute Size:** `Standard_D2s_v5` (2 vCPUs, 8 GB RAM)
* **Storage Allocation:** 16 GB OS Disk (`Standard_LRS`)
* **Identity Management:** User-Assigned Managed Identity for Azure RBAC
* **Post-Deployment Configuration (via Cloud-Init):**
  * System packages updated via `dnf`
  * Python 3 package environment installed
  * New local system user (`devuser`) initialized with password access
  * Sudoers policy configured (`/etc/sudoers.d/devuser`) with `NOPASSWD` execution access

---

## Prerequisites

Before executing this deployment, ensure your local workstation features the following components:

1. [Terraform CLI](https://hashicorp.com) (v1.0.0 or higher)
2. [Azure CLI](https://microsoft.com) (Logged into your active target tenant)
3. An active **SSH Public/Private Key pair** (Default expected location: `~/.ssh/id_rsa.pub`)

---

## Deployment Steps

Follow these sequential steps to provision the Azure infrastructure resources:

### 1. Initialize the Workspace
Prepare the directory and automatically retrieve the required HashiCorp Microsoft Azure (`azurerm`) logic providers:
```bash
terraform init
```

### 2. Authenticate to Microsoft Azure
Establish a secure command session to your target Azure subscription directory:
```bash
az login
```
*Note: If you manage multiple active cloud accounts, force target the proper directory slot manually via:*
```bash
az account set --subscription "YOUR_SUBSCIPTION_ID_HERE"
```

### 3. Generate Execution Forecast
Preview exactly what explicit virtual resources Terraform plans to build within your cloud tenant boundary:
```bash
terraform plan
```

### 4. Execute the Cloud Deployment
Provision the network plumbing, security identities, public IP endpoints, and the RHEL instance:
```bash
terraform apply
```
*When prompted by the terminal safety checkpoint interface, type **`yes`** and press **Enter**.*

---

## Validation & Testing

Once deployment completes, the terminal will display the generated output parameters:

```text
Outputs:
vm_public_ip = "YOUR_VM_PUBLIC_IP_HERE"
```

### Verification Tasks

1. **SSH Connection:** Log in securely via your primary administration profile string:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@YOUR_VM_PUBLIC_IP_HERE
   ```

2. **User Profiles:** Switch contexts into the new secondary execution environment shell:
   ```bash
   su - devuser
   ```

3. **Validation Commands:** Check that the runtime configurations successfully completed:
   ```bash
   # Confirm Sudo administrative escalation access
   sudo dnf check-update

   # Confirm Python 3 interpreter environment
   python3 --version
   ```

---

## Tearing Down Resources

To clean up and destroy all provisioned assets to avoid ongoing Azure billing charges:
```bash
terraform destroy
```
*(Type **`yes`** to confirm deletion when prompted).*
