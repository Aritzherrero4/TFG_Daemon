CC = g++
CFLAGS = -std=c++17 -lstdc++fs -lcryptopp -Wall -lsystemd 
BLFLAGS = -shared -O3
IDIR = ./include/
SDIR = ./src/
ODIR = ./obj/
BDIR = ./bin/
LDIR = ./lib/
BLAKE = ./external/blake3/
BLIB = ./lib/libblake3.so
LIBDIR=$(abspath $(LDIR))
LD = -Wl,-rpath,$(LIBDIR) -L$(LIBDIR) -I$(BLAKE)
arch := $(shell uname -m)

main:$(SDIR)fsCheckDaemon.cpp $(IDIR)fsCheckDaemon.hpp $(ODIR)mnode.o $(ODIR)mtree.o $(IDIR)mtree.hpp $(ODIR)utils.o $(IDIR)utils.hpp

	@echo Compiling fsCheckDaemon...
	@g++ $(LD) -o fsCheckDaemon $(SDIR)fsCheckDaemon.cpp $(ODIR)mtree.o $(ODIR)mnode.o $(ODIR)utils.o -lblake3 $(CFLAGS) -lpthread
	@echo Done 

$(ODIR)utils.o: $(SDIR)utils.cpp $(IDIR)utils.hpp
	@echo Compiling utils...
	@g++ -c $(SDIR)utils.cpp -o $(ODIR)utils.o -std=c++17 -lstdc++fs -Wall

$(ODIR)mnode.o: $(SDIR)mnode.cpp $(IDIR)mnode.hpp
	@echo Compiling mnode...
	@g++ $(LD) -c $(SDIR)mnode.cpp -o $(ODIR)mnode.o -lblake3 $(CFLAGS) 

$(ODIR)mtree.o: $(SDIR)mtree.cpp $(IDIR)mtree.hpp $(IDIR)mnode.hpp
	@echo Compiling mtree...
	@g++ -c $(SDIR)mtree.cpp -o $(ODIR)mtree.o $(CFLAGS)


	@/bin/bash -c "if [ ! -f ./lib/libblake3.so ]; then \
		make blake; \
	fi"

blake:
	@echo 'Blake lib not detected...'; 
ifeq ($(arch),x86_64)
	@echo "Target x86_64 detected for blake3..."
	@echo "Compiling blake for x86_64..."
	@gcc $(BLFLAGS) -o $(LDIR)libblake3.so $(BLAKE)blake3.c $(BLAKE)blake3_dispatch.c $(BLAKE)blake3_portable.c $(BLAKE)blake3_sse2_x86-64_unix.S $(BLAKE)blake3_sse41_x86-64_unix.S $(BLAKE)blake3_avx2_x86-64_unix.S $(BLAKE)blake3_avx512_x86-64_unix.S -lm
endif

ifneq ($(filter $(arch), arm64 aarch64),)
	@echo "Target arm detected for blake3..."
	@echo "Compiling blake for arm..."
	@gcc -shared -O3 -o $(LDIR)libblake3.so -DBLAKE3_USE_NEON $(BLAKE)blake3.c $(BLAKE)blake3_dispatch.c $(BLAKE)blake3_portable.c $(BLAKE)blake3_neon.c		
endif
	@echo Done
.PHONY : clean, all, clean-all, fresh

all: blake main
fresh: clean-all all
clean :
	@echo Cleaning object files and the executable...
	@rm $(ODIR)*
	@rm fsCheckDaemon
	@echo Done
clean-all:
	@echo Cleaning object files, the executable and blake3 lib...
	@rm $(LDIR)*
	@rm $(ODIR)*
	@rm fsCheckDaemon
	@echo Done

