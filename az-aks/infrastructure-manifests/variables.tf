variable "location" {
  type    = string
  default = "westeurope"
}

variable "prefix" {
  type    = string
  default = "kkdcd7"
  validation {
    condition     = length(var.prefix) <= 6
    error_message = "The prefix value must not be longer than 6 characters."
  }
}

variable "env" {
  type    = string
  default = "dev"
}

variable "sqldbusername" {
  type    = string
  default = "akssqladmin"
}

variable "sqldbpassword" {
  type    = string
  default = ""
}