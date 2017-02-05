/*
	Simple test du hardware. On charge un main avec une boucle qui 
	attend dans un premier temps l'appuis sur un bouton et ensuite effectue
	un échantillonnage et recommence.
*/

#include <stdio.h>
#include <stdlib.h>
#include <sleep.h>
#include <time.h>

#include "platform.h"
#include "xparameters.h"
#include "xuartps_hw.h"
#include "xtime_l.h"
#include "xil_cache.h"

#include "platform_config.h"


//  	 /* RAPPELS */
//  	*(tx_addr + 11) = ADDR
//   	*(tx_addr + 12) = FREQ
//   	*(tx_addr + 13) =NB_ECH/16
//   	*(tx_addr + 10) = TRIGGER 1 = front montant
//   	*(tx_addr + 9) = SIGNAL SELECTION 1 = btn
//		0x5f5e100;//1Hz
//		0x989680;//10Hz
//		0xf4240;//100Hz
//		0x186a0;//1000Hz
//		0x18d22;//Arduino 1000Hz

//\brief configure l'IP avec les valeurs données
void configure_IP(volatile unsigned int *ip_addr,
			unsigned int addr,
			unsigned int freq,
			unsigned int nbr_ech,
			unsigned int trigger,
			unsigned int signal_sel)
{
	*(ip_addr + 11) = (unsigned int)addr;
	*(ip_addr + 12) = freq;
	*(ip_addr + 13) = nbr_ech;
	*(ip_addr + 10) =trigger;
	*(ip_addr + 9) = signal_sel;
}

/*
 * \brief configure l'IP pour attendre un push sur le bouton
 */
void configure_BTN(volatile unsigned int *ip_addr)
{
	extern unsigned int _end;
	*(ip_addr + 11) = (unsigned int)&_end;
	*(ip_addr + 12) = 0x186a0;
	*(ip_addr + 13) = 1;
	*(ip_addr + 10) =1;
	*(ip_addr + 9) = 1;
}

//\brief simple parcours sur les données et comptage du nobmre d'échantillons à l'état haut pour
//calculer une fréquence
unsigned int get_freq(volatile unsigned int * arr,unsigned int arr_size,unsigned int ech_freq){
	unsigned int counter = 0;
	unsigned int i = 0;
	while(i < arr_size && arr[i] != 1)i++;
	while(i < arr_size && arr[i] == 1){
		i++;
		counter++;
	}
	printf("Count : %d \r\n", counter);
	return 1.0/((double)counter/(double)ech_freq);
}


int main(void)
{
   init_platform();
   cleanup_platform();
   print("Simple Validation\r\n");

   extern unsigned int _end;
   volatile unsigned *arr = &_end;
   volatile unsigned int *ip_addr = (volatile unsigned int *)0x43C00000;

   while(1){
	   print("Wait on btn 2\r\n");
	   configure_BTN(ip_addr);
	   *ip_addr = 0;
	   while (*(ip_addr +  0) == 1)sleep(1);

	   print("Sampling\r\n");
	   configure_IP(ip_addr, (unsigned int)arr, 0x2710,1024/16,1,2);

	   *ip_addr = 0;
	   while (*(ip_addr +  0) == 1)sleep(1);

	   printf("Freq. detected : %d Hz\r\n", get_freq(arr,1024,0x5f5e100/0x2710));

   }

   cleanup_platform();
   return 0;
}
