variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-vm-availability-logicapp"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "logic_app_name" {
  description = "Name of the Logic App"
  type        = string
  default     = "la-vm-availability-monitor"
}

variable "subscription_id" {
  description = "Azure subscription ID for Resource Graph queries"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid GUID format."
  }
}

variable "email_recipient" {
  description = "Email address to receive notifications"
  type        = string
  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.email_recipient))
    error_message = "Must be a valid email address."
  }
}

variable "office365_connection_name" {
  description = "Name of the Office 365 connection"
  type        = string
  default     = "office365"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    Purpose     = "VM Availability Monitoring"
  }
}