output "subscription_vm_inventory" {
  value       = local.vm_raw_list
  description = "Summary block indicating all Virtual Machine infrastructure status logs discovered."
}