loaderSRC = $(wildcard loader/*.asm)
loaderBIN = $(loaderSRC:.asm=.bin)

loader.bin: $(loaderBIN)
	dd if=/dev/zero of=threeOS.img conv=notrunc bs=1048576 count=1
	
	dd if=$^ of=threeOS.img conv=notrunc
	
	od -Ax -x threeOS.img

%.bin : %.asm
	nasm -f bin $< -o $@

clean:
	rm threeLoader/*.bin
