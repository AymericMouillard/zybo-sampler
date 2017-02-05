#include <linux/init.h>           // Macros used to mark up functions e.g. __init __exit
#include <linux/module.h>         // Core header for loading LKMs into the kernel
#include <linux/device.h>         // Header to support the kernel Driver Model
#include <linux/kernel.h>         // Contains types, macros, functions for the kernel
#include <linux/fs.h>             // Header for the Linux file system support
#include <asm/uaccess.h>          // Required for the copy to user function
#include <asm/io.h>
#include <asm/cacheflush.h>
#include <linux/semaphore.h>
#include <linux/delay.h>

#define DEVICE_NAME "fpga_manip"
#define CLASS_NAME "ebb"

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Aymeric Mouillard");
MODULE_DESCRIPTION("FPGA manipulator v_copy");
MODULE_VERSION("0.1");

static struct semaphore safe_init_mutex;
#define FPGA_WRITE_ZONE_SIZE 0x5000000
volatile void *trigger_reg;
volatile void *dest_addr_reg;
volatile void *occ16_reg;
volatile void *signal_reg;
volatile void *trigger_edge_reg;
volatile void *freq_reg;
volatile void *fpga_write_zone;
volatile void *error_reg;
const unsigned int dest_addr = 0x15000000;



static int majorNumber;
static char message[256] = {0};
static short size_of_message = 0;

#define BUFFER_SIZE 65536
static char data[BUFFER_SIZE] = {0};
static int data_size;
static ssize_t execute_mem_transfer(char* buffer, loff_t *offset, size_t requested)
{
        size_t i;
        int error_count = 0;
        // If this is the first transfer, we allocate the memory to be read
        if(fpga_write_zone == NULL) {
                fpga_write_zone = ioremap_nocache(dest_addr, FPGA_WRITE_ZONE_SIZE);
        }
        // Because we will read words
	size_t max_addr = fpga_write_zone + data_size * 4;
	size_t current_addr = fpga_write_zone + *offset;
        // Calculate the size of the read
        size_t true_len = requested > BUFFER_SIZE ? BUFFER_SIZE : requested;
	true_len = true_len > (max_addr-current_addr) ? (max_addr-current_addr) : true_len;
        for(i = 0; i < true_len/4; i++) {
                data[i*4] = ioread8(fpga_write_zone + *offset + i*4);
                data[i*4 + 1] = ioread8(fpga_write_zone + *offset + i*4 + 1);
                data[i*4 + 2] = ioread8(fpga_write_zone + *offset + i*4 + 2);
                data[i*4 + 3] = ioread8(fpga_write_zone + *offset + i*4 + 3);
        }
        //Check for failure
        if(error_count) {                                               
                return -EFAULT;                                         
        }
        // Copy the data to the user
        copy_to_user(buffer, data, true_len);
        *offset = *offset + true_len;
        // If this is the last transfer, unmap the memory
        if(current_addr + true_len >= fpga_write_zone + data_size * 4) {
                iounmap(fpga_write_zone);
                fpga_write_zone = NULL;
        }
        // Return the size of the data passed to the user
        return true_len;
}
static int numberOpens = 0;
static struct class* ebb_fpga_manip_cpy_CLASS = NULL;
static struct device* ebb_fpga_manip_cpy_DEVICE = NULL;

static int dev_open(struct inode*, struct file*);
static int dev_release(struct inode*, struct file*);
static ssize_t dev_read(struct file*, char*, size_t, loff_t*);
static ssize_t dev_write(struct file*, const char*, size_t, loff_t*);

// Declaration of the driver operations : others are NULL
static struct file_operations fops =
{
        .open = dev_open,
        .read = dev_read,
        .write = dev_write,
        .release = dev_release,
};
/* STATES 
 * IDLE 0
 * SET 1
 * CAPTURING 2
 * CAPTURED 3
 * READING 4
 */
#define IDLE 0
#define SET 1
#define CAPTURING 2
#define CAPTURED 3
#define READING 4
/* COMMANDS
 * INIT nb -> SUCCESS/FAILURE
 * LAUNCH -> SUCCESS/FAILURE
 * FINISHED -> YES/NO/ERR
 * READ -> nothing (the data, return_code setted to unknown, 
 *                                      shouldn't be reached)
 * STATUS -> the state
 * anything else -> unknown
 */
#define SUCCESS 0
#define FAILURE 1
#define YES 2
#define NO 3
#define STATE 4
#define UNKNOWN 5
#define ERR 6
//Usefull for the FSM
static int current_state;
static int return_code;
static uint32_t to_uint32(char* number)
{
        uint32_t ret = 0;
        uint32_t i;
        for(i = 0; i < 4; i++) {
                ret = ret << 8;
                ret |= number[i];
        }
        return ret;
}
static int perform_init(char* number)
{
        uint32_t ech,signal,trigger,freq;
        uint32_t i;
        // TODO : UNSECURE
        ech = to_uint32(number);
        signal = to_uint32(number + 4);
        trigger = to_uint32(number + 8);
        freq = to_uint32(number + 12);
        data_size = ech * 16;
        //printk(KERN_ALERT "Data size asked is %d\n",data_size);
        //printk(KERN_ALERT "signal,trigger,freq : %d,%d,%d\n",signal,trigger,freq);
        iowrite32(ech,occ16_reg); 
        iowrite32(signal,signal_reg); 
        iowrite32(trigger,trigger_edge_reg); 
        iowrite32(freq,freq_reg); 
        return SUCCESS;
}
static int perform_launch(void) 
{
        iowrite32(0x1,trigger_reg);
        //Readback
        uint32_t trigger_rb = ioread32(trigger_reg);
        //printk(KERN_ALERT "trigger_reg value is %d\n",trigger_rb);
        return (trigger_rb == 1) ? SUCCESS : FAILURE;
}
static int perform_finished(void)
{
        if(ioread32(trigger_reg) == 0) {
                if(ioread32(error_reg) != 0) {
                        return ERR;
                }
		//printk(KERN_ALERT "Is flushing cache\n");
                flush_cache_all();
		//printk(KERN_ALERT "Cache flushed\n");
                return YES;
        }
        return NO;
}
static int perform_command(char* command)
{
        //Here stands the fsm calculator
        int next_step = current_state;
        return_code = UNKNOWN;
        if(strcmp(command,"STATUS") == 0) {
                return_code = STATE;
                return STATE;
        }
        switch(current_state)
        {
                case IDLE:
                        if(strncmp(command,"INIT ",5) == 0) {
                                command += 5;
                                return_code = perform_init(command);
                                if(return_code == SUCCESS) {
                                        next_step = SET;
                                }
                        }
                        break;
                case SET:
                        if(strcmp(command,"LAUNCH") == 0) {
                                return_code = perform_launch();
                                if(return_code == SUCCESS) {
                                        next_step = CAPTURING;
                                }
                        }
                        break;
                case CAPTURING:
                        if(strcmp(command,"FINISHED") == 0) {
                                return_code = perform_finished();
                                if(return_code == YES) {
                                        next_step = CAPTURED;
                                }
                        }
                        break;
                case CAPTURED:
                        if(strcmp(command,"READ") == 0) {
                                return_code = UNKNOWN;
                                next_step = READING;
                        }
                        break;
                case READING:
                        next_step = IDLE;
                        data_size = 0;
                        break;
        }
        current_state = next_step;
        return return_code;
}
const char* generate_message(void)
{
        //Here stands the message generator according to the return code
        if(return_code == SUCCESS) {
                return "SUCCESS";
        }
        if(return_code == FAILURE) {
                return "FAILURE";
        }
        if(return_code == YES) {
                return "YES";
        }
        if(return_code == NO) {
                return "NO";
        }
        if(return_code == ERR) {
                return "ERR";
        }
        if(return_code == STATE) {
                if(current_state == IDLE) {
                        return "IDLE";
                }
                if(current_state == SET) {
                        return "SET";
                }
                if(current_state == CAPTURING) {
                        return "CAPTURING";
                }
                if(current_state == CAPTURED) {
                        return "CAPTURED";
                }
        }
        return "UNKNOWN";
}

static int cpymod_init(void)
{
        current_state = IDLE;
        return_code = UNKNOWN;
        data_size = 0;
        sema_init(&safe_init_mutex,1);
        printk(KERN_ALERT "Initializing FPGA manipulator vcopy\n");
        majorNumber = register_chrdev(0, DEVICE_NAME, &fops);
        if(majorNumber<0) {
                printk(KERN_ALERT "Unable to load the module");
                return majorNumber;
        }
        printk(KERN_ALERT "FPGA manipulator vcopy initialized with mn %d\n",majorNumber);
        ebb_fpga_manip_cpy_CLASS = class_create(THIS_MODULE, CLASS_NAME);
        if (IS_ERR(ebb_fpga_manip_cpy_CLASS)){                // Check for error and clean up if there is
                unregister_chrdev(majorNumber, DEVICE_NAME);
                printk(KERN_ALERT "Failed to register device class\n");
                return PTR_ERR(ebb_fpga_manip_cpy_CLASS);          // Correct way to return an error on a pointer
        }
        ebb_fpga_manip_cpy_DEVICE = device_create(ebb_fpga_manip_cpy_CLASS, NULL, MKDEV(majorNumber, 0), NULL, DEVICE_NAME);
        if (IS_ERR(ebb_fpga_manip_cpy_DEVICE)){               // Clean up if there is an error
                class_destroy(ebb_fpga_manip_cpy_CLASS);           // Repeated code but the alternative is goto statements
                unregister_chrdev(majorNumber, DEVICE_NAME);
                printk(KERN_ALERT "Failed to create the device\n");
                return PTR_ERR(ebb_fpga_manip_cpy_DEVICE);
        }

        // Allocate the regsters memory
        // Addresses are given by the IP
        trigger_reg      = ioremap(0x83C00000, 0x4);
        dest_addr_reg    = ioremap(0x83c0002c, 0x4);
        occ16_reg        = ioremap(0x83c00034, 0x4);
        freq_reg         = ioremap(0x83c00030, 0x4);
        signal_reg       = ioremap(0x83c00024, 0x4);
        trigger_edge_reg = ioremap(0x83c00028, 0x4);
        error_reg        = ioremap(0x83c00018, 0x4);
        // reg = <0x0 0x15000000>;
        fpga_write_zone = NULL;
        //Set the destination addr
        iowrite32(dest_addr,dest_addr_reg);
        return 0;
}
static void cpymod_exit(void)
{
        //Unmap the memory
        iounmap(trigger_reg);
        iounmap(dest_addr_reg);
        iounmap(occ16_reg);
        iounmap(signal_reg);
        iounmap(trigger_edge_reg);
        iounmap(freq_reg);
        iounmap(error_reg);

        device_destroy(ebb_fpga_manip_cpy_CLASS, MKDEV(majorNumber, 0));     // remove the device
        class_unregister(ebb_fpga_manip_cpy_CLASS);                          // unregister the device class
        class_destroy(ebb_fpga_manip_cpy_CLASS);                             // remove the device class
        unregister_chrdev(majorNumber, DEVICE_NAME);             // unregister the major number
        printk(KERN_ALERT "Terminating FPGA manipulator vcopy\n");
}
static int dev_open(struct inode *inodep, struct file *filep){
        down(&safe_init_mutex);
        numberOpens++;
        if(numberOpens != 1) {
                numberOpens--;
                up(&safe_init_mutex);
                return -1;
        }
        up(&safe_init_mutex);
        if(ioread32(trigger_reg) == 1) { // The device is busy right now
                return -1;
        }
        current_state = IDLE;
        return_code = UNKNOWN;
        return 0;
}
static ssize_t dev_read(struct file *filep, char *buffer, size_t len, loff_t *offset){
        int error_count = 0;
        size_t true_len;
        if(current_state != READING) {
                sprintf(message, "%s", generate_message());   // appending received string with its length
                size_of_message = strlen(message);                 // store the length of the stored message
                message[size_of_message] = '\0'; // TODO CHECK SIZE
                error_count = copy_to_user(buffer, message, size_of_message + 1);
                if(error_count) {
                        return -EFAULT;
                }
                true_len = strlen(message);
                return (true_len < len) ? true_len : len;
        } 
        return execute_mem_transfer(buffer, offset, len);
}
static ssize_t dev_write(struct file *filep, const char *buffer, size_t len, loff_t *offset){
        //TODO : security flaw HERE
        int i;
        memcpy(message,buffer,len);
        size_of_message = strlen(message);// store the length of the stored message
        if(len > size_of_message) {
                size_of_message = len;
        }
        message[size_of_message] = '\0'; // TODO CHECK SIZE
        perform_command(message);
        return len;
}
static int dev_release(struct inode *inodep, struct file *filep){
        down(&safe_init_mutex);
        numberOpens--;
        up(&safe_init_mutex);
        return 0;
}
module_init(cpymod_init);
module_exit(cpymod_exit);

