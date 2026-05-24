packer {
  required_plugins {
    qemu = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "costapine" {
  iso_url           = "output/costapine-x86_64.iso"
  iso_checksum      = "none"
  output_directory  = "output"
  shutdown_command  = "sudo poweroff"
  disk_size         = "8192"
  format            = "qcow2"
  accelerator       = "kvm"
  ssh_username      = "costapine"
  ssh_password      = "costapine"
  ssh_timeout       = "20m"
  vm_name           = "costapine.qcow2"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "10s"
  boot_command = [
    "<enter>",
    "<wait30>",
    "sudo costapine-installer.sh<enter>",
    "<wait5>",
    # Automatic installation sequence through dialog TUI
    "<enter>",  # OK welcome
    "<enter>",  # Select default disk
    "<enter>",  # Confirm select disk
    "<enter>",  # Yes confirmation
    "<enter>",  # Select auto partitioning
    "<wait5>",
    "<enter>",  # Select format confirmation
    "<wait5>",
    "<enter>",  # Select mount confirmation
    "<wait15>", # Wait for copy files
    "<enter>",  # Confirm default hostname
    "<enter>",  # Confirm default timezone
    "costapine<enter>", # Enter username
    "costapine<enter>", # Enter password
    "costapine<enter>", # Confirm password
    "<wait5>",
    "<enter>",  # Install bootloader
    "<wait15>", # Wait for bootloader setup
    "<enter>",  # Complete installation
    "<wait5>",
    "n"         # Do not reboot now
  ]
}

build {
  sources = ["source.qemu.costapine"]
}
