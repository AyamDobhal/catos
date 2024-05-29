.PHONY: setup image qemu
.EXPORT_ALL_VARIABLES:

setup:
	curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain none
	rustup show
	cargo install bootimage

# Compilation options
memory = 32
output = video
keyboard = qwerty
mode = release

# Emulation options
nic = rtl8139
audio = coreaudio
signal = off
kvm = false
pcap = false
trace = false
monitor = false

export CATOS_VERSION = $(shell git describe --tags | sed "s/^v//")
export CATOS_MEMORY = $(memory)
export CATOS_KEYBOARD = $(keyboard)


bin = target/x86_64-catos/$(mode)/bootimage-catos.bin
img = disk.img

$(img):
	qemu-img create $(img) 32M


cargo-opts = --no-default-features --features $(output) --bin catos
ifeq ($(mode),release)
	cargo-opts += --release
endif

image: $(img)
	touch src/lib.rs
	env | grep CATOS
	cargo bootimage $(cargo-opts)
	dd conv=notrunc if=$(bin) of=$(img)

qemu-opts = -m $(memory) -drive file=$(img),format=raw \
			 -audiodev $(audio),id=a0 -machine pcspk-audiodev=a0 \
			 -netdev user,id=e0,hostfwd=tcp::8080-:80 -device $(nic),netdev=e0
ifeq ($(kvm),true)
	qemu-opts += -cpu host -accel kvm
else
	qemu-opts += -cpu core2duo
endif

ifeq ($(pcap),true)
	qemu-opts += -object filter-dump,id=f1,netdev=e0,file=/tmp/qemu.pcap
endif

ifeq ($(monitor),true)
	qemu-opts += -monitor telnet:127.0.0.1:7777,server,nowait
endif

ifeq ($(output),serial)
	qemu-opts += -display none
	qemu-opts += -chardev stdio,id=s0,signal=$(signal) -serial chardev:s0
endif

ifeq ($(mode),debug)
	qemu-opts += -s -S
endif


qemu:
	qemu-system-x86_64 $(qemu-opts)

test:
	cargo test --release --lib --no-default-features --features serial -- \
		-m $(memory) -display none -serial stdio \
		-device isa-debug-exit,iobase=0xF4,iosize=0x04


clean:
	cargo clean
	rm -f $(img)