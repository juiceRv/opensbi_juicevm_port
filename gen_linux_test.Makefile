all: 
	# CONFIG_DEBUG_INFO和CONFIG_GDB_SCRIPTS
	- rm ../../../../../linux-5.0/arch/riscv/boot/Image
	make -C ../../../../../linux-5.0/ ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j
	cp -f ../../../../../linux-5.0/arch/riscv/boot/Image ../
	rm platform/juice/juiceRv/juice_vm.dtb
	dtc -I dts -O dtb -o platform/juice/juiceRv/juice_vm.dtb platform/juice/juiceRv/juice_vm.dts
	make CROSS_COMPILE=riscv64-unknown-linux-gnu- PLATFORM=juice/juiceRv FW_PAYLOAD_PATH=../Image clean
	make CROSS_COMPILE=riscv64-unknown-linux-gnu- PLATFORM=juice/juiceRv FW_PAYLOAD_PATH=../Image -j
	rm -f /mnt/ramdisk/vmlinux_dump.S opensbi_master_dump.S
	# sudo mount -t tmpfs -o size=1024m tmpfs /mnt/ramdisk
	riscv64-unknown-linux-gnu-objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data --debugging --disassemble-all -S --syms ../../../../../linux-5.0/vmlinux > /mnt/ramdisk/vmlinux_dump.S
	riscv64-unknown-linux-gnu-objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data --debugging --disassemble-all -S --dynamic-syms --syms build/platform/juice/juiceRv/firmware/fw_payload.elf > opensbi_master_dump.S
	# ../../../juicevm_debug -d -g -t -s -L1 build/platform/juice/juiceRv/firmware/fw_payload.bin  | tee /mnt/ramdisk/test.log

run:
	../../../juicevm_debug -a -t -T -M -g -s build/platform/juice/juiceRv/firmware/fw_payload.bin | tee /mnt/ramdisk/test.log

clean:
	make -C ../../../../../risc-v_linux_kernel/linux-5.0/ ARCH=riscv CROSS_COMPILE=riscv64-linux- clean
	make CROSS_COMPILE=riscv64-linux- PLATFORM=juice/juiceRv FW_PAYLOAD_PATH=../Image clean
	rm -f ../../../../../risc-v_linux_kernel/linux-5.0/arch/riscv/boot/Image
	rm -f ../../../../../risc-v_linux_kernel/linux-5.0/arch/riscv/boot/Image.gz

fs:
	riscv64-linux-gnu-as -march=rv64imac -o rootfs/init.o rootfs/init.S
	riscv64-linux-gnu-ld -o rootfs/init rootfs/init.o
	riscv64-linux-gnu-gcc -march=rv64i -mabi=lp64 -mcmodel=medany --static  rootfs/init.c -o rootfs/init
	riscv64-linux-gcc -march=rv64i -mabi=lp64 -mcmodel=medany --static  rootfs/init.c -o rootfs/init
	genext2fs -b 4096 -d rootfs ramdisk

qemu:
	make -C opensbi_origin_and_qemu_bootok CROSS_COMPILE=riscv64-linux- PLATFORM=generic FW_PAYLOAD_PATH=/mnt/ssd_prj/risc-v_linux_kernel/linux-5.0/arch/riscv/boot/Image
	/opt/qemu/bin/qemu-system-riscv64 -M virt -m 256M -nographic -bios  opensbi_origin_and_qemu_bootok/build/platform/generic/firmware/fw_payload.elf
