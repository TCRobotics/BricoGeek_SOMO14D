/////////////////////////////////////////////
// Alex TC (TCRobotics)                    //
//web: http://tcrobotics.blogspot.com      //
//twitter: @TCRobotics                     //
//email: alex.tc.robotics-AT-gmail.com     //
/////////////////////////////////////////////
//Basado en el codigo de: Doyle Maleche -> maleche1 at comcast dot net

const unsigned int minVol= 0xfff0;    // Volumen minimo
const unsigned int maxVol= 0xfff7;    // Volumen maximo
const unsigned int PlyPse = 0xfffe;   // Play o Pause
const unsigned int Stop= 0xFFFF;      // Stop
const int pinClock= 8;
const int pinData =9;
const int pinBusy =10;
const int pinReset=11;
unsigned int volLevel=0x0005;
int Song;                             // Pista de audio actual
unsigned int vol;                     // Volumen actual


void setup(){
Serial.begin(9600);
pinMode(pinData,OUTPUT);     // Pin de datos
pinMode(pinClock,OUTPUT);    // Pin del reloj
pinMode(pinReset,OUTPUT);    // Pin para resetear
pinMode(pinBusy,INPUT);      // Pin de SOMO14D ocupado
Reset();
}

void loop()
{

PlaySong(0);

while(1){}

}






/**********************************************************************************
                        Secuencia de envio
**********************************************************************************/

void sendData(int ThisSong)
{
int TheSong = ThisSong;
int ClockCounter=0;
int ClockCycle=15;//0x0f;

digitalWrite(pinClock,HIGH);     // Espera 300ms para el que enpiece el envio de datos
delay(300); 
digitalWrite(pinClock,LOW);      // Espera 2ms para enviar
delay(2); 
   
      while(ClockCounter <= ClockCycle)
    { digitalWrite(pinClock,LOW); 
      if (TheSong & 0x8000)
       {digitalWrite(pinData,HIGH);
       }
        else
       {digitalWrite(pinData,LOW);
    }
    TheSong = TheSong << 1;
    delayMicroseconds(200);      //Reloj a nivel bajo 200us
     digitalWrite(pinClock,HIGH);
    ClockCounter++;
    delayMicroseconds(200);      //Reloj a nivel alto 200us
   }

digitalWrite(pinData,LOW);
digitalWrite(pinClock,HIGH);    // Ponemos el reloj a nivel alto para indicar fin de transmision
}

/**********************************************************************************
                        Reproduce la cancion seleccionada por numero
**********************************************************************************/

void PlaySong(int SongNumber)
{ sendData(Stop);

  if (SongNumber >= 512 || SongNumber <0){      //avisa si la pista de audio esta fuera de los limites
   Serial.print("La pista de audio ");
   Serial.print(SongNumber);
   Serial.println(" no esta entre 0 y 512");}
 
  if (SongNumber >= 0 && SongNumber < 512){     
   Serial.print("-> Pista de audio: ");
   Serial.println(SongNumber);
   sendData(SongNumber);}
}

/**********************************************************************************
                  	Reproduce la siguiente cancion
**********************************************************************************/
void nextPlay()
{
if (Song >= 0 && Song < 512){ Song++;} // debe estar en el rango de 512
if (Song >= 512 || Song <0){ Song=0;}
Serial.print("Pista de audio: ");
Serial.println(Song);
sendData(Song);
}


/**********************************************************************************
                  	Reproduce o pausa la pista de audio actual
**********************************************************************************/
void pausePlay()
{
Serial.println("Play/Pause.");
sendData(PlyPse);
}

/**********************************************************************************
                        Para la pista de audio
**********************************************************************************/
void stopPlay()
{ 
Serial.println("Stop.");
sendData(Stop);
}

/**********************************************************************************
                        Incrementa el volumen
**********************************************************************************/
void incVol()
{ 
if (vol >= minVol && vol < maxVol){ vol++;} // debe estar dentro del rango de volumen
if (vol >= maxVol | vol <minVol){ vol=maxVol;}
int tVol=vol;                        
volLevel = tVol - 0xfff0;
Serial.print("Volumen incrementado: ");
Serial.println( volLevel);
sendData(tVol);

}
/**********************************************************************************
                         Decrementa el volumen
**********************************************************************************/
void decVol()
{
if (vol > minVol && vol <= maxVol){ vol--;} // debe estar dentro del rango de volumen
if (vol >= maxVol | vol <minVol){vol=maxVol;}
int tVol=vol;                             
volLevel = tVol-0xfff0; // los niveles de volumen 0 a 7. el codigo de volumen va de fff0 a fff7
Serial.print("Volumen decrementado: ");
Serial.println(volLevel);
sendData(tVol);
}

/**********************************************************************************
                         Reset SOMO
**********************************************************************************/
void Reset()
{
Serial.println("RESET.");
digitalWrite(pinReset,LOW);
delay(50);
digitalWrite(pinReset,HIGH);
Song=0;
}

/**********************************************************************************
                         Reproduce todas las pistas de audio consecutivamente 
**********************************************************************************/
void CycleSongs()
{int Busy=0;
 long Start=0;
for(Song=0;Song< 512;Song++)          //empieza con el archivo 0 acaba con el 511
{ 
 Start=0;                              //Resetea el temporizador
  Serial.print("Cancion en ciclo: ");
  Serial.println(Song);
  Start=millis();                      // leemos el tiempo inicial
  sendData(Song);                     // reproducimos la pista de audio
  delay(50);                           
    do                                   
  {
    Busy =digitalRead(pinBusy);        
  }
  while(Busy !=0);                     //esperamos a que termine de reproducir   
  if (millis()-Start < 900){break;}    
                            
 
}
Song=0;                                // reseteamos el numero de pista a 0
}
