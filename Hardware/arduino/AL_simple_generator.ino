/*
	Simple programme Arduino qui positionne sur la sortie digitale 12 un simple
	signal alternant entre '0' et '1'.
	On utilise ce programme pour tester l'échantillonnage sur la carte zybo.
*/
 
int out_pin = 12;

boolean output = false;

void setup() {
  pinMode(out_pin, OUTPUT); 
}

void loop() {
  if (output){
      digitalWrite(out_pin, HIGH);
  }else{
      digitalWrite(out_pin, LOW);
  }
  output = !output;
  delay(10);
}
