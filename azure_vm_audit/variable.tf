variable "azure_subscription_id" {
  type        = string
  description = "The target Azure subscription ID to audit."
  default     = "78f4786e-e0fb-497b-b0d9-2e72ddc950d8"
}

variable "nexus_user" {
  type        = string
  description = "The username authorized to write artifacts to ://abc.com."
  sensitive   = true
}

variable "nexus_pass" {
  type        = string
  description = "The password or API token authorized to write artifacts to ://abc.com."
  sensitive   = true
}