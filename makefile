ARCH            = $(shell uname -m | sed s,i[3456789]86,ia32,)
OBJS            = main.o
TARGET          = quartz.efi
EFIINC          = /usr/include/efi
EFIINCS					= -I$(EFIINC) -I$(EFIINC)/$(ARCH) -I$(EFIINC)/protocol
LIB							= /usr/lib
EFILIB					= /usr/lib
EFI_CRT_OBJS		= $(EFILIB)/crt0-efi-$(ARCH).o
EFI_LDS					= $(EFILIB)/elf_$(ARCH)_efi.lds
CFLAGS					= $(EFIINCS) -fno-stack-protector -fpic \
									-fshort-wchar -mno-red-zone -Wall

ifeq ($(ARCH),x86_64)
  CFLAGS += -DEFI_FUNCTION_WRAPPER
endif

LDFLAGS         = -nostdlib -znocombreloc -T $(EFI_LDS) -shared \
									-Bsymbolic -L $(EFILIB) -L $(LIB) $(EFI_CRT_OBJS)

all: $(TARGET)
	rm *.o
	rm *.so

quartz.so: $(OBJS)
	ld $(LDFLAGS) $(OBJS) -o $@ -lefi -lgnuefi

%.efi: %.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
		-j .dynsym  -j .rel -j .rela -j .reloc \
		--target=efi-app-$(ARCH) $^ $@

install:
	sudo cp quartz.efi /boot/efi/EFI

qemu: all
	uefi-run -b /usr/share/ovmf/x64/OVMF_CODE.fd -q qemu-system-x86_64 $(TARGET)