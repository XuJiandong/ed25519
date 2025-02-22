TARGET := riscv64-unknown-linux-gnu
CC := $(TARGET)-gcc
LD := $(TARGET)-gcc
OBJCOPY := $(TARGET)-objcopy
CFLAGS := -fno-builtin-printf -fdata-sections -ffunction-sections -fPIC -O3 -nostdinc -nostdlib -nostartfiles -fvisibility=hidden -I deps/ckb-c-stdlib -I deps/ckb-c-stdlib/libc -I deps -I deps/ckb-c-stdlib/molecule -I c -I build -Wall -Wno-nonnull -Wno-nonnull-compare -Wno-unused-function -Wno-unused-variable -g
LDFLAGS := -Wl,-static -Wl,--gc-sections

# docker pull nervos/ckb-riscv-gnu-toolchain:gnu-bionic-20191012
BUILDER_DOCKER := nervos/ckb-riscv-gnu-toolchain@sha256:aae8a3f79705f67d505d1f1d5ddc694a4fd537ed1c7e9622420a470d59ba2ec3

all: build/ed25519_demo

all-via-docker:
	docker run --rm -v `pwd`:/code ${BUILDER_DOCKER} bash -c "cd /code && make"
	
build/ed25519_demo: build/test.o build/libed25519.a
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	cp $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/test.o: test.c
	$(CC) -c $(filter-out -DCKB_DECLARATION_ONLY, $(CFLAGS)) $(LDFLAGS) -o $@ $^

build/%.o: src/%.c
	$(CC) -c -DCKB_DECLARATION_ONLY $(CFLAGS) $(LDFLAGS) -o $@ $^

build/libed25519.a: build/sign.o build/verify.o build/sha512.o build/sc.o build/keypair.o build/key_exchange.o build/ge.o build/fe.o build/add_scalar.o
	$(AR) r $@ $^

fmt:
	clang-format -i -style=Google test.c


run:
	ckb-debugger --bin build/ed25519_demo

clean:
	rm -rf build/*.debug
	rm -rf build/*.o
	rm -rf build/ed25519_demo
	rm -rf build/libed25519.a

dist: clean all

.PHONY: all all-via-docker dist clean fmt
