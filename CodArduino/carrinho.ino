#include <TimerOne.h>
#include <Ultrasonic.h>
#include "SoftwareSerial.h"

SoftwareSerial bluetooth(10, 11);  // RX, TX (Bluetooth)
Ultrasonic ultrasonic(3,2); //Trigger, Echo (Ultrasonico)

// Define os pinos de utilização na Ponte H.
const int motorA1  = 4;    
const int motorA2  = 5;    
const int motorB1  = 6;   
const int motorB2  = 7;   
// Declaraçao de outras variaveis
int cmSensor;
int velocidade;
char state;

void setup() {   
  
  Timer1.initialize(2000000); // Timer dura 2 seg
  Timer1.attachInterrupt( timerIsr ); // Funcao chamada a cada 2 seg
  
  //Modo de operaçao dos pinos e taxa de comunicaçao
  Serial.begin(9600);
  bluetooth.begin(9600);
  pinMode(motorA1, OUTPUT);
  pinMode(motorA2, OUTPUT);
  pinMode(motorB1, OUTPUT);
  pinMode(motorB2, OUTPUT);
  
}

void loop() {
  // Leitura do pino A0 (Divisao por 4 para obtermos o valor numa faixa entre 0 e 255)
  velocidade = analogRead(A0)/4;
  // Capturando o valor em cm do sensor ultrasonico
  long microsec = ultrasonic.timing();
  cmSensor = ultrasonic.convert(microsec, Ultrasonic::CM);
  
  // State ser 'S' caso nenhum comando seja dado
  state = 'S';
  // Se o bluetooth enviar algum sinal, entre nessa funçao
  if (bluetooth.available() > 0) {
    // State recebe o sinal que foi enviado via bluetooth
    state = bluetooth.read(); 
    // Caso o sensor capture um valor <= 20 e o sinal enviado seja 'C', continue com 'S' na variavel state 
    if(cmSensor <=20 ){
      if(state=='C'){
        state = 'S';
      }
    }
  }
 
    // Se o estado recebido for igual a 'C', o carro se movimenta para frente.
    if (state == 'C') {
      analogWrite(motorB1, velocidade);
      analogWrite(motorA1, velocidade);
      analogWrite(motorA2, 0);
      analogWrite(motorB2, 0);
      delay(300);
    }
    // Se o estado recebido for igual a 'B', o carro se movimenta para trás.
    else if (state == 'B') {
      analogWrite(motorA1, 0);
      analogWrite(motorB1, 0);
      analogWrite(motorB2, velocidade);
      analogWrite(motorA2, velocidade);
      delay(300);  
    }
    // Se o estado recebido for igual a 'D', o carro se movimenta para esquerda.
    else if (state == 'D') {
      analogWrite(motorA1, 0);
      analogWrite(motorA2, velocidade);
      analogWrite(motorB1, velocidade);
      analogWrite(motorB2, 0);
      delay(300);
    }
    // Se o estado recebido for igual a 'E', o carro se movimenta para direita.
    else if (state == 'E') {  
      analogWrite(motorA1, velocidade);
      analogWrite(motorA2, 0);
      analogWrite(motorB1, 0);
      analogWrite(motorB2, velocidade);
      delay(300);
    }
    // Se o estado recebido for igual a 'S', o carro permanece parado.
    else if (state == 'S') { 
      analogWrite(motorA1, 0);
      analogWrite(motorA2, 0);
      analogWrite(motorB1, 0);
      analogWrite(motorB2, 0);
    }
}

void timerIsr(){ 
  int i,n;
  char numeros;
  int analise = cmSensor;
  String strSensor = String(cmSensor);
  int tamanho = strSensor.length()+1;
  Serial.println(cmSensor);
  for(i=0;i<tamanho;i++){
   if(i==tamanho-1)bluetooth.write(70);
   else{
     n = analise%10;
     numeros = n+'0';
     bluetooth.write(numeros);
     analise = analise/10;
   }
  }
}
