# Azure Virtual Machine Infrastructure Status Audit

An automated utility that leverages Terraform, native Azure CLI, and curl to query, transform, and export live Virtual Machine (VM) operational status data directly to an enterprise Nexus repository.

## 📁 Directory Structure

For this automation engine to execute correctly, all core files must reside together within a single workspace directory on your Linux instance:

```text
~/azure-vm-audit/
├── main.tf              # Core Terraform orchestration and data query pipelines
├── variables.tf         # Input variable schemas and configurations
├── outputs.tf           # Post-apply terminal reporting blocks
└── run_azure_audit.sh   # Master shell orchestrator and user-space log rotation
```

## 🚀 Workflow Execution Flow

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

## 📋 Security Architecture (Credential Management)

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
