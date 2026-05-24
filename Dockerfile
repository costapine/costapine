FROM alpine:3.21

# Install build dependencies
RUN apk add --no-cache \
    xorriso \
    squashfs-tools \
    grub-efi \
    grub-bios \
    mtools \
    syslinux \
    dosfstools \
    cpio \
    bash \
    rsync \
    curl \
    wget \
    git \
    tar \
    gzip

# Set up build directories
WORKDIR /build
COPY . /build

# Mount point for output
VOLUME /output

# Entrypoint script
ENTRYPOINT ["/bin/bash", "-c", "\
    set -euo pipefail; \
    echo '=== Costapine ISO Build starting inside Docker ==='; \
    # Create build directories \
    ROOTFS_DIR='/tmp/rootfs'; \
    ISO_DIR='/tmp/iso_root'; \
    mkdir -p $ROOTFS_DIR $ISO_DIR; \
    \
    # Bootstrap Alpine rootfs \
    echo 'Bootstrapping Alpine rootfs...'; \
    apk --root $ROOTFS_DIR --initdb add alpine-base apk-tools; \
    \
    # Configure repositories in rootfs \
    cp rootfs/overlay/etc/apk/repositories $ROOTFS_DIR/etc/apk/repositories; \
    \
    # Install packages \
    echo 'Installing packages...'; \
    for list in rootfs/packages/*.list; do \
        echo \"Installing packages from $list\"; \
        apk --root $ROOTFS_DIR add $(grep -v '^#' \"$list\" | grep -v '^$'); \
    done; \
    \
    # Copy overlay files \
    echo 'Applying rootfs overlay...'; \
    cp -a rootfs/overlay/* $ROOTFS_DIR/; \
    \
    # Create users & groups \
    echo 'Configuring users...'; \
    chroot $ROOTFS_DIR /bin/sh -c '\
        adduser -D -s /bin/bash -G wheel costapine; \
        echo \"costapine:costapine\" | chpasswd; \
        echo \"root:costapine\" | chpasswd; \
        addgroup costapine video; \
        addgroup costapine audio; \
        addgroup costapine input; \
    '; \
    \
    # Configure services \
    echo 'Configuring services...'; \
    chroot $ROOTFS_DIR /bin/sh -c '\
        rc-update add dbus default; \
        rc-update add elogind default; \
        rc-update add sddm default; \
        rc-update add networkmanager default; \
        rc-update add costapine-init default; \
    '; \
    \
    # Apply branding \
    echo 'Applying branding...'; \
    mkdir -p $ROOTFS_DIR/usr/share/jwm; \
    cp branding/jwm/*.jwmrc $ROOTFS_DIR/usr/share/jwm/; \
    cp branding/jwm/autostart.sh $ROOTFS_DIR/usr/share/jwm/autostart.sh; \
    chmod +x $ROOTFS_DIR/usr/share/jwm/autostart.sh; \
    \
    mkdir -p $ROOTFS_DIR/usr/share/sddm/themes/costapine-theme; \
    cp -a branding/sddm/costapine-theme/* $ROOTFS_DIR/usr/share/sddm/themes/costapine-theme/; \
    \
    mkdir -p $ROOTFS_DIR/usr/share/backgrounds; \
    cp branding/wallpapers/costapine-default.png $ROOTFS_DIR/usr/share/backgrounds/; \
    \
    mkdir -p $ROOTFS_DIR/usr/share/pixmaps; \
    cp branding/icons/costapine-logo.svg $ROOTFS_DIR/usr/share/pixmaps/; \
    \
    # Apply installer \
    echo 'Applying installer...'; \
    mkdir -p $ROOTFS_DIR/usr/local/bin $ROOTFS_DIR/usr/local/lib/costapine-installer; \
    cp installer/costapine-installer.sh $ROOTFS_DIR/usr/local/bin/; \
    cp -a installer/lib/* $ROOTFS_DIR/usr/local/lib/costapine-installer/; \
    chmod +x $ROOTFS_DIR/usr/local/bin/costapine-installer.sh; \
    # Patch installer.sh paths to point to correct library location \
    sed -i \"s|SCRIPT_DIR=\\\"\$(cd \\\"\\\$(dirname \\\"\\\$0\\\")\\\" \&\& pwd)\\\"|SCRIPT_DIR=\\\"/usr/local/lib/costapine-installer\\\"|g\" $ROOTFS_DIR/usr/local/bin/costapine-installer.sh; \
    \
    # Cleanup unnecessary files \
    echo 'Cleaning up rootfs...'; \
    rm -rf $ROOTFS_DIR/var/cache/apk/*; \
    \
    # Create squashfs \
    echo 'Creating filesystem.squashfs...'; \
    mkdir -p $ISO_DIR/live; \
    mksquashfs $ROOTFS_DIR $ISO_DIR/live/filesystem.squashfs -comp xz -b 256K; \
    \
    # Build initramfs \
    echo 'Building initramfs...'; \
    INITRAMFS_TMP='/tmp/initramfs_tmp'; \
    mkdir -p $INITRAMFS_TMP/bin $INITRAMFS_TMP/sbin $INITRAMFS_TMP/etc $INITRAMFS_TMP/proc $INITRAMFS_TMP/sys $INITRAMFS_TMP/dev $INITRAMFS_TMP/mnt; \
    cp iso/initramfs/init $INITRAMFS_TMP/init; \
    chmod +x $INITRAMFS_TMP/init; \
    # Pack initramfs \
    (cd $INITRAMFS_TMP && find . -print0 | cpio --null -ov --format=newc | gzip -9 > $ISO_DIR/boot/initramfs-costapine) || \
    (cd $INITRAMFS_TMP && find . | cpio -ov -H newc | gzip -9 > $ISO_DIR/boot/initramfs-costapine); \
    \
    # Copy kernel \
    echo 'Copying kernel...'; \
    mkdir -p $ISO_DIR/boot; \
    KERNEL_VER=$(ls $ROOTFS_DIR/lib/modules | head -n1); \
    cp $ROOTFS_DIR/boot/vmlinuz-lts $ISO_DIR/boot/vmlinuz-lts; \
    \
    # Setup isolinux for BIOS \
    echo 'Configuring isolinux for BIOS boot...'; \
    mkdir -p $ISO_DIR/boot/isolinux; \
    cp iso/syslinux/isolinux.cfg $ISO_DIR/boot/isolinux/isolinux.cfg; \
    cp /usr/share/syslinux/isolinux.bin $ISO_DIR/boot/isolinux/ || cp /usr/lib/syslinux/bios/isolinux.bin $ISO_DIR/boot/isolinux/; \
    cp /usr/share/syslinux/ldlinux.c32 $ISO_DIR/boot/isolinux/ || cp /usr/lib/syslinux/bios/ldlinux.c32 $ISO_DIR/boot/isolinux/; \
    cp /usr/share/syslinux/libcom.c32 $ISO_DIR/boot/isolinux/ || cp /usr/lib/syslinux/bios/libcom.c32 $ISO_DIR/boot/isolinux/ || true; \
    cp /usr/share/syslinux/libutil.c32 $ISO_DIR/boot/isolinux/ || cp /usr/lib/syslinux/bios/libutil.c32 $ISO_DIR/boot/isolinux/ || true; \
    cp /usr/share/syslinux/vesamenu.c32 $ISO_DIR/boot/isolinux/ || cp /usr/lib/syslinux/bios/vesamenu.c32 $ISO_DIR/boot/isolinux/ || true; \
    cp /usr/share/syslinux/reboot.c32 $ISO_DIR/boot/isolinux/ || cp /usr/lib/syslinux/bios/reboot.c32 $ISO_DIR/boot/isolinux/ || true; \
    cp /usr/share/syslinux/poweroff.c32 $ISO_DIR/boot/isolinux/ || cp /usr/lib/syslinux/bios/poweroff.c32 $ISO_DIR/boot/isolinux/ || true; \
    cp branding/splash/costapine-splash.png $ISO_DIR/boot/isolinux/splash.png; \
    \
    # Setup GRUB for UEFI \
    echo 'Configuring GRUB for UEFI boot...'; \
    mkdir -p $ISO_DIR/boot/grub; \
    cp iso/grub/grub.cfg $ISO_DIR/boot/grub/grub.cfg; \
    grub-mkstandalone -d /usr/lib/grub/x86_64-efi -O x86_64-efi \
        -o $ISO_DIR/boot/grub/BOOTX64.EFI \
        \"boot/grub/grub.cfg=iso/grub/grub-embed.cfg\"; \
    \
    # Create EFI System Partition FAT image \
    mkdir -p /tmp/efi_img/EFI/BOOT; \
    cp $ISO_DIR/boot/grub/BOOTX64.EFI /tmp/efi_img/EFI/BOOT/BOOTX64.EFI; \
    dd if=/dev/zero of=$ISO_DIR/boot/grub/efiboot.img bs=1M count=4; \
    mkfs.vfat -F 12 -n 'ESP' $ISO_DIR/boot/grub/efiboot.img; \
    mcopy -i $ISO_DIR/boot/grub/efiboot.img -s /tmp/efi_img/* ::/; \
    \
    # Generate ISO \
    echo 'Generating ISO using xorriso...'; \
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid 'COSTAPINE' \
        -eltorito-boot boot/isolinux/isolinux.bin \
        -eltorito-catalog boot/isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -output /output/costapine-x86_64.iso \
        $ISO_DIR; \
    \
    sha256sum /output/costapine-x86_64.iso > /output/costapine-x86_64.iso.sha256; \
    echo '=== Costapine ISO Build successful! ==='; \
"]
