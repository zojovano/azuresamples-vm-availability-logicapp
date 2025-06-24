variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = "539d8bb1-bbd5-4f9d-836d-223c3e6d1e43"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-vm-availability-logicapp"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Sweden Central"
}

variable "logic_app_name" {
  description = "Name of the Logic App"
  type        = string
  default     = "la-vm-availability-monitor"
}

variable "managed_identity_name" {
  description = "Name of the managed identity"
  type        = string
  default     = "mi-vm-availability-logicapp"
}

variable "office365_connection_name" {
  description = "Name of the Office 365 connection"
  type        = string
  default     = "office365-connection"
}

variable "app_service_plan_name" {
  description = "Name of the WorkflowStandard Plan for Logic App Standard"
  type        = string
  default     = "asp-vm-availability-logicapp"
}

variable "storage_account_name" {
  description = "Name of the storage account for Logic App Standard"
  type        = string
  default     = "stavmavaillogicapp"
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
}

variable "target_subscription_id" {
  description = "Subscription ID to monitor for VM availability"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Project     = "vm-availability-monitoring"
    ManagedBy   = "terraform"
  }
}