FROM alpine:3.21

# Install build dependencies
RUN apk add --no-cache     xorriso     squashfs-tools     grub-efi     grub-bios     mtools     syslinux     dosfstools     cpio     bash     rsync     curl     wget     git     tar     gzip

# Set up build directories
WORKDIR /build
COPY . /build

# Write build.sh by decoding the base64 payload
RUN echo "$B64_SCRIPT" | base64 -d > /build/build.sh

RUN chmod +x /build/build.sh

# Mount point for output
VOLUME /output

ENTRYPOINT ["/bin/bash", "/build/build.sh"]
