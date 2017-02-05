/*
	Ce programme Arduino génère un signal numérique à partir de valeurs hexadécimales
	Pour chaque valeurs, on la transofmr en mot de 16 bits que l'on va ensuite 
	positionné dont les valeurs seront positionnées de façon successive en sortie
	du pin 12.
*/
 
int out_pin = 12;

/*
	On transforme ces messages de leur forme hex à leur forme 
	binaire et on utilise cette nouvelle forme pour générer un signal numérique.
*/
unsigned int messages[] = {
                            0xFFFF,
                            0x0000,
                            0xF0F0,
                            0x0F0F,
                            0xAAAA,
                            0x5555
                          };

//contient la forme binaire des messages plus haut
unsigned int processedMsgs[6][16];

//varialbes d'état du processus d'émission de message
int current_message = 0;
int count = 0;
int nb_messages = 6;

void setup() {                
  pinMode(out_pin, OUTPUT);
  //transformation des messages hexa en binaires
  for(int i = 0 ; i  < nb_messages; i++){
    for(int j = 0 ; j  < 16; j++){
      int mask = 0x1<<(15-j);
      unsigned int v = (messages[i] & mask)>>(15-j);
      if (v){
        processedMsgs[i][j]=true;
      }else{
        processedMsgs[i][j]=false;
      }
    }      
  }
  delay(10000);//attente pour brancher l'arduino à la carte
}

void loop() {
  if (current_message < nb_messages){
    if (processedMsgs[current_message][count]){
        digitalWrite(out_pin, HIGH);
    }else{
        digitalWrite(out_pin, LOW);
    }
    count ++;
  }
  if(count == 16){
    current_message++;
    count = 0;
  }
  delay(1);
}
