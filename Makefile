.PHONY: all iso clean test

all: iso

iso:
	@echo "Building Costapine ISO via Docker..."
	mkdir -p output
	docker build -t costapine-builder .
	docker run --privileged -v $$(pwd)/output:/output costapine-builder

clean:
	@echo "Cleaning up outputs..."
	rm -rf output/

test:
	@echo "Testing bootable ISO in QEMU (BIOS mode)..."
	qemu-system-x86_64 -cdrom output/costapine-x86_64.iso -m 1024 -enable-kvm -cpu host || \
	qemu-system-x86_64 -cdrom output/costapine-x86_64.iso -m 1024
