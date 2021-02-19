variable "centos_7_img_url" {
  description = "centos 7 image"
  default = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
}

variable "vm_hostname" {
  description = "vm hostname"
  default     = "centos"
}

variable "ssh_username" {
  description = "the ssh user to use"
  default     = "kpaten"
}

variable "ssh_private_key" {
  description = "the private key to use"
  default     = "~/.ssh/id_local_cloud"
}
