
/*************************************************
* Filename: SOMODuino
* Created:  22 April 2010
* Author:   Doyle Maleche -> maleche1 at comcast dot net
* Description: Arduino code to test the SOMO-14D with Serial
*              Modifed code from 4dsystems to work with Arduino
* Version: 0.1
**************************************************/
// 
// Use HyperTerminal or any Terminal program to benefit from the screen refresh
// This code is works with the Arduino
// Please let me know of any updates you may add so I can learn from it.
const unsigned int minVol= 0xfff0;    // Minimum volume
const unsigned int maxVol= 0xfff7;    // Max Volume   
const unsigned int PlyPse = 0xfffe;   // Play or Pause
const unsigned int Stop= 0xFFFF;      // Stop
const int pinClock= 8;
const int pinData =9;
const int pinBusy =10;
const int pinReset=11;
unsigned int volLevel=0x0005;
int Song;                             // current Song
unsigned int vol;                     // current volume


void setup(){
Serial.begin(9600);
pinMode(pinData,OUTPUT);     // set pin 4 to output for Data
pinMode(pinClock,OUTPUT);    // set pin 3 to output for data
pinMode(pinReset,OUTPUT);    // set pin 7 to allow software reset
pinMode(pinBusy,INPUT);      // set pin 6 to monitor while Song is playing
Reset();
}

void loop()
{
 int cmd;
  if (Serial.available()>0) {
  cmd=Serial.read();          // Read the user command
  delay(10);
  Serial.println(cmd,BYTE);   // Print user selection
  // Check user input command. You could use the CASE/SWITCH function here instead of IF
   if (cmd==110){nextPlay();}  //"n" =Play Next Song
   if (cmd==112){pausePlay();} //"p" =Pause/Play
   if (cmd==116){stopPlay();}  //"t" = Stop Play
   if (cmd==115){PlaySong();}  //"sx"; x=Play Song Number
   if (cmd==105){incVol();}    //"i" = Increase Volume
   if (cmd==100){decVol();}    //"d" = Decrease Volume
   if (cmd==114){Reset();}     //"r" = Reset
   if (cmd==99){CycleSongs();} //"c" = Cycle through all Songs
   
   delay(2000);                // Pause 2 seconds to show User selection
   Menu();                      //Refresh Menu
 }
 
}

void Menu()
{
  Serial.print(12,BYTE);   // Clear terminal. Works with real terminal programs like HyperTerminal. Ardunio's serial monitor will not clear.
  Serial.println("*************************************");
  Serial.println("*             SOMO-14D              *");
  Serial.println("*     Arduino Serial controlled     *");
  Serial.println("*       Test and Evaluation         *");
  Serial.println("*************************************");
  Serial.println();
  Serial.println("n  = Play Next Song");
  Serial.println("p  = Pause or Play current Song");
  Serial.println("t  = Stop current Song");
  Serial.println("sxxx = Play Song number 000 - 511");
  Serial.println("i  = Increase Volume");
  Serial.println("d  = Decrease Volume");
  Serial.println("c  = Cycle through all Songs");
  Serial.println("r  = Reset SOMO and goto sleep");
  Serial.println("=====================================");
  Serial.print("Enter command > ");
}


/************************************************** ********************************
                               Send Sequence
************************************************** ********************************/

void sendData(int ThisSong)
{
int TheSong = ThisSong;
int ClockCounter=0;
int ClockCycle=15;//0x0f;

digitalWrite(pinClock,HIGH);     // Hold (idle) for 300msec to prepare data start
delay(300); 
digitalWrite(pinClock,LOW);       //Hold for 2msec to signal data start
delay(2);  //2msec delay
   
      while(ClockCounter <= ClockCycle)
    { digitalWrite(pinClock,LOW); 
      if (TheSong & 0x8000)
       {digitalWrite(pinData,HIGH);
       }
        else
       {digitalWrite(pinData,LOW);
    }
    TheSong = TheSong << 1;
    delayMicroseconds(200);      //Clock cycle period is 200 uSec - LOW
     digitalWrite(pinClock,HIGH);
    ClockCounter++;
    delayMicroseconds(200);      //Clock cycle period is 200 uSec - HIGH
   }

digitalWrite(pinData,LOW);
digitalWrite(pinClock,HIGH);    // Place clock high to signal end of data
}

/************************************************** ********************************
                        Plays Stored Song by Number
************************************************** ********************************/

void PlaySong()
{ sendData(Stop);
  int input[3];
  int Index=0;
Serial.print("Enter Song Number (000-511): " );
Serial.flush();

do     
  { if(Serial.available()> 0)    //Wait for each number input
    {  
     Index++;                        // Increment input array index  
     input[Index]=Serial.read()-48;  // assign number to input array (ASCII value - 48 returns 0 through 9)
     Serial.print(input[Index]);    // Print each number
     Serial.flush();                 // Clear serial buffer to reset Serial.available to 0
   }  
}
while (Index < 3);                  // Count each number until three are entered (000 to 511)
    int SongNumber=input[1]*100 + input[2] *10 + input[3];    // Add the numbers in the correct decimal order
     delay(5);
   if (SongNumber >= 512 || SongNumber <0){      // Warn if song number is not within range limit
   Serial.print(SongNumber);
   Serial.println(" is not within 0 and 512");}
 
  if (SongNumber >= 0 && SongNumber < 512){     // Song is within range limit
   Serial.print("-> Song No.");
   Serial.println(SongNumber);
   sendData(SongNumber);}

}

/************************************************** ********************************
                  Plays the next Song in the Sequence
************************************************** ********************************/
void nextPlay()
{
if (Song >= 0 && Song < 512){ Song++;} // should be within the 512 number range
if (Song >= 512 || Song <0){ Song=0;}
Serial.print("Song No.");
Serial.println(Song);
sendData(Song);
}


/************************************************** ********************************
                  Play/Pause function, play or pause the Song
************************************************** ********************************/
void pausePlay()
{
Serial.println("Play/Pause.");
sendData(PlyPse);
}

/************************************************** ********************************
                                    Stop Song
************************************************** ********************************/
void stopPlay()
{ 
Serial.println("Stop.");
sendData(Stop);
}

/************************************************** ********************************
                                 Increase Volume
************************************************** ********************************/
void incVol()
{ 
if (vol >= minVol && vol < maxVol){ vol++;} // should be within the volume range
if (vol >= maxVol | vol <minVol){ vol=maxVol;}
int tVol=vol;                              // Temp Volume
volLevel = tVol - 0xfff0;
Serial.print("Increase volume.=");
Serial.println( volLevel);
sendData(tVol);

}
/************************************************** ********************************
                                Decrease Volume
************************************************** ********************************/
void decVol()
{
if (vol > minVol && vol <= maxVol){ vol--;} // should be within the volume range
if (vol >= maxVol | vol <minVol){vol=maxVol;}
int tVol=vol;                              // Temp Volume
volLevel = tVol-0xfff0; // levels are from 0 to 7. volume code is fff0 - fff7
Serial.print("Decrease volume.");
Serial.println(volLevel);
sendData(tVol);
}

/************************************************** ********************************
                                 Reset SOMO
************************************************** ********************************/
void Reset()
{
//Serial.println("RESET.");
digitalWrite(pinReset,LOW);
delay(50);
digitalWrite(pinReset,HIGH);
Song=0;
  Menu();
}

/************************************************** ********************************
                     Cycle Through and play all sound files 
************************************************** ********************************/
void CycleSongs()
{int Busy=0;
 long Start=0;
for(Song=0;Song< 512;Song++)          //Start with file 0 end with file 511
{ 
 Start=0;                              //Reset Start timer
  Serial.print("Cycle Song=");
  Serial.println(Song);
  Start=millis();                      // Set Start timer to current clock cycle (internal to MCU)
  sendData(Song);                     // Play current Song
  delay(50);                           // Wait for BUSY signal (LED) to initialize
    do                                 // Start wait loop   
  {
    Busy =digitalRead(pinBusy);        // Read Busy pin status. While Song is playing, Busy == 1
  }
  while(Busy !=0);                     // Keep reading Busy pin until end of Song. Busy == 0   
  if (millis()-Start < 900){break;}    // Test if we are at the last song
                                       // if the difference between the current MCU timer and Start timer is < 900ms,
                                       // we are at end or the Song is too short. Exit the FOR/LOOP 
 
}
Song=0;                                // reset song number to 0
Menu();                                // refresh display
}
void RandomSongs()
{
 Serial.print("Work in progress");
}

 
