 * Install petalinux tools and Xilinx SDK

 * Clonage the Diligent repository:
git clone https://github.com/Digilent/petalinux-bsps.git

 * Create the petalinux project :
petalinux -create  --type  project  --name ZyboLinux --source petalinux-bsps/releases/Digilent-Zybo-Linux-BD-v2015.4.bsp
cd ZyboLinux

 * Configure the Harware :
petalinux -config --get -hw -description=../../Software/petalinux

 * Initial configuration :
petalinux-config

 * Add dropbear ssh server with the menu :
petalinux-config -c rootfs

 * Create the module and the application with :
petalinux-create -t modules -n fpga_manip
petalinux-create -t apps --template c++ --name driver_exploit

 * Copy the sources :
cp ../app/driver_exploit.cpp components/apps/driver_exploit/driver_exploit.cpp
cp ../module/fpga_manip.c components/modules/fpga_manip/fpga_manip.c

 * Edit system-conf.dtsi :
vim subsystems/linux/configs/device-tree/system-conf.dtsi

 * Replace :
serial0 = &uart1;
 * By :
serial0 = &uart1;
serial1 = &uart0;

 * And replace :
reg = <0x0 0x20000000>;
 * By :
reg = <0x0 0x15000000>;

 * Add the new app and the new module with : (in Apps and Modules)
petalinux-config -c rootfs

 * Compile :
petalinux-build

 * Then pack the bitstream .bit with BOOT.BIN :
petalinux-package --boot --format BIN --fsbl ../fsbl/fsbl.elf --fpga ../../Software/petalinux/linux_bd_wrapper.bit --u-boot --force


 * Now you are able to put BOOT.BIN and images/linux/image.ub to the SD card
 * The system is ready to use
