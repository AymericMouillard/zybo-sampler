/* 
	Ce test est prévu pour fonctionner avec
	le générateur de valeur codé pour l'arduino.
	On effectue l'échantillonnage à la fréquence correspondant
	à la fréquence programmée dans l'arduino. A la fin, on parcours les valeurs
	afin de vérifier le bon déroulement de l'échantillonnage.
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

int main(void)
{
   init_platform();
   cleanup_platform();

   extern unsigned int _end;

#define ARRAY_SIZE ((1<<10) * 16)
   // Try to access memory
   volatile unsigned int *tx_addr = (volatile unsigned int *)0x43C00000;
   volatile unsigned *arr = &_end;

   /* Configure TX */
   *(tx_addr + 11) = (unsigned int)arr;
   //*(tx_addr + 12) = 0x5f5e100;//1Hz
   //*(tx_addr + 12) = 0x989680;//10Hz
   //*(tx_addr + 12) = 0xf4240;//100Hz
   //*(tx_addr + 12) = 0x186a0;//1000Hz
   *(tx_addr + 12) = 0x18d22;//FALSE 1000Hz

   *(tx_addr + 13) = 6;//nb ech / 16
   *(tx_addr + 10) = 1	;//trigger état haut
   *(tx_addr + 9) = 2	;//selection sig
   //0x5f5e100 = 1 seconde

   *tx_addr = 0; // Trigger the start of the transfert

   /* Busy waiting for the transfert to be done */
   unsigned int r;
   while ((r = *(tx_addr +  0)) == 1);
   unsigned int i = 0;
	for ( i = 0; i < 6; i++) {
		unsigned int ii = 0;
		unsigned int val = 0;
		for ( ii = 0; ii < 16; ii++) {
			val = val << 1;
			val = val | arr[i*16+ii];
		}
		printf("Value n° %d ; equals: %04x\n",i,val);
	}

   cleanup_platform();
   return 0;
}
