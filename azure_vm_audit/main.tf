terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

data "external" "az_cli_vm_audit" {
  program = [
    "bash", "-c",
    <<-EOT
      az vm list \
        --subscription "${var.azure_subscription_id}" \
        --show-details \
        --query "{
          vm_data: to_string(
            map(&{
              ResourceGroup: resourceGroup, 
              Name: name, 
              Location: location, 
              Size: hardwareProfile.vmSize, 
              PowerState: powerState, 
              OS: storageProfile.osDisk.osType
            }, @)
          )
        }"
    EOT
  ]
}

locals {
  vm_raw_list = jsondecode(data.external.az_cli_vm_audit.result.vm_data)
  
  csv_header = "Name,ResourceGroup,Location,Size,OS,PowerState\n"
  csv_rows   = join("\n", [
    for vm in local.vm_raw_list : 
    "${vm.Name},${vm.ResourceGroup},${vm.Location},${vm.Size},${vm.OS},${vm.PowerState}"
  ])
  full_csv_payload = "${local.csv_header}${local.csv_rows}"
}

resource "local_file" "csv_inventory" {
  filename = "${path.module}/azure_vms_inventory_status.csv"
  content  = local.full_csv_payload
}

resource "null_resource" "convert_to_excel" {
  depends_on = [local_file.csv_inventory]

  provisioner "local-exec" {
    command = "python3 -c \"import pandas as pd; pd.read_csv('azure_vms_inventory_status.csv').to_excel('azure_vms_inventory_status.xlsx', index=False)\""
  }
}

resource "null_resource" "upload_csv_to_nexus" {
  depends_on = [null_resource.convert_to_excel]

  provisioner "local-exec" {
    command = <<EOT
      curl -v -u "$${NEXUS_USERNAME}:$${NEXUS_PASSWORD}" \
        -X PUT \
        -H "Content-Type: text/csv" \
        --data-binary @azure_vms_inventory_status.csv \
        "https://abc.com"
    EOT

    environment = {
      NEXUS_USERNAME = var.nexus_user
      NEXUS_PASSWORD = var.nexus_pass
    }
  }
}