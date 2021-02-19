provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centos7-qcow2" {
  name = "centos.qcow2"
  pool = "default"
  source = var.centos_7_img_url
  format = "qcow2"
}

#User creds info injected by cloud init

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.yml")}"
}

# Network information injected by cloud init

data "template_file" "network_config" {
  template = "${file("${path.module}/network_config.yml")}"
}

# Use CloudInit to add the instance

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data = "${data.template_file.user_data.rendered}"
}

# Define KVM domain to create

resource "libvirt_domain" "centos" {
  name   = var.vm_hostname
  memory = "2048"
  vcpu   = 1

  network_interface {
    network_name = "default"
    wait_for_lease = true
    hostname = var.vm_hostname
  }

  disk {
    volume_id = "${libvirt_volume.centos7-qcow2.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }

    connection {
      type                = "ssh"
      user                = var.ssh_username
      host                = libvirt_domain.centos.network_interface[0].addresses[0]
      private_key         = file(var.ssh_private_key)
      timeout             = "2m"
    }

  provisioner "local-exec" {
    command = <<EOT
      echo "[nginx]" > nginx.ini
      echo "${libvirt_domain.centos.network_interface[0].addresses[0]}" >> nginx.ini
      echo "[nginx:vars]" >> nginx.ini
      echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" >> nginx.ini
      ansible-playbook -u ${var.ssh_username} --private-key ${var.ssh_private_key} -i nginx.ini ~/projects/ansible/playbook.yml
      EOT
  }
}

# Output Server IP at end of terraform apply

output "ip" {
  value = "${libvirt_domain.centos.network_interface.0.addresses.0}"
}
output "url" {
  value = "http://${libvirt_domain.centos.network_interface[0].addresses[0]}"
}
