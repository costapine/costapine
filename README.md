# Costapine Linux

A lightweight, modern, from-scratch Linux distribution based on **Alpine Linux v3.21**, featuring the **JWM** window manager and the **SDDM** login manager. Optimized for low RAM usage, fast boot times, and old hardware while offering a premium visual experience.

## Project Structure

Costapine is organized into a modular multi-repository architecture:

- [costapine-rootfs](https://github.com/costapine/costapine-rootfs) (Submodule `rootfs/`): Packages and overlay filesystems.
- [costapine-iso](https://github.com/costapine/costapine-iso) (Submodule `iso/`): Bootloader configuration (BIOS + UEFI) and custom live init script.
- [costapine-installer](https://github.com/costapine/costapine-installer) (Submodule `installer/`): Dialog-based TUI system installer.
- [costapine-branding](https://github.com/costapine/costapine-branding) (Submodule `branding/`): JWM configs, themes, wallpapers, and SDDM theme.
- [costapine-kernel](https://github.com/costapine/costapine-kernel) (Submodule `kernel/`): Reference Linux kernel configurations.
- [costapine-docs](https://github.com/costapine/costapine-docs) (Submodule `docs/`): Comprehensive documentation and guides.

## Build Systems

Costapine supports 3 separate ways to build the bootable ISO:

### 1. GitHub Actions CI (Primary)
The entire OS is built declaratively via the GitHub Actions workflow `.github/workflows/build-iso.yml`. Pushing to `main` or tagging a version automatically generates a new ISO release.

### 2. Docker (Local Build)
You can build the ISO locally on any distribution running Docker:
```bash
make iso
```
The final ISO and checksum will be saved to `output/costapine-x86_64.iso`.

### 3. Packer (VM Image)
Generate a VM disk image (`qcow2`) using Packer:
```bash
packer build packer/costapine.pkr.hcl
```

## Running & Testing

To test the bootable ISO in QEMU:
```bash
make test
```
