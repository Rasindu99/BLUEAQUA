#include <OneWire.h>                            //Temperature Sensor Libraries
#include <DallasTemperature.h>                  //Temperature Sensor Libraries
#include <Wire.h>                               //Turbidity Sensor Libraries 
#include <EEPROM.h>                             //TDS Sensor Libraries 
#include "GravityTDS.h"                         //TDS Sensor Libraries 
#include <LiquidCrystal_I2C.h>                  //LCD Display Library

LiquidCrystal_I2C lcd(0x27, 20, 4); // set the LCD address to 0x27 for a 20 chars and 4 line display
const int temperatureSensorPin = 2;
const int floatSwitchPin = 3;
const int trigPin1 = 7;
const int echoPin1 = 6;
const int trigPin2 = 5;
const int echoPin2 = 4;
const int relayPin1 = 8;
const int relayPin2 = 9;
const int relayPin3 = 10;
const int relayPin4 = 11;
const int relayPin5 = 12;
const int buzzerPin = 13;
const int turbiditySensorPin = A0;
const int tdsSensorPin = A1;
const int pHSensorPin = A2;
int buttonState = 1;
int count1=0;
OneWire oneWire(temperatureSensorPin);
DallasTemperature sensors(&oneWire);
GravityTDS gravityTds;


void setup() {
  Serial.begin(9600);
  sensors.begin();                              //Getting the Temperature Sensor to Start
  gravityTds.setPin(tdsSensorPin);
  gravityTds.setAref(5.0);                      //reference voltage on ADC, default 5.0V on Arduino UNO
  gravityTds.setAdcRange(1024);                 //1024 for 10bit ADC
  gravityTds.begin();                           //initialization
  pinMode(floatSwitchPin, INPUT_PULLUP);        //Set the float switch pin as an input
  pinMode(trigPin1, OUTPUT);                    //Sets the trigPin1 as an Output
  pinMode(echoPin1, INPUT);                     //Sets the echoPin1 as an Input
  pinMode(trigPin2, OUTPUT);                    //Sets the trigPin2 as an Output
  pinMode(echoPin2, INPUT);                     //Sets the echoPin2 as an Input
  pinMode(relayPin1, OUTPUT);
  pinMode(relayPin2, OUTPUT);
  pinMode(relayPin3, OUTPUT);
  pinMode(relayPin4, OUTPUT);
  pinMode(relayPin5, OUTPUT);
  pinMode(buzzerPin, OUTPUT);                   //Set the buzzer pin as an output
  lcd.init();                                   //initialize the lcd
  lcd.backlight();                              //Turn on the LCD screen backlight
}

void loop() {
  float waterlevel;
  float distance1=0;
  float distance2=0;
  distance1=getDistance(trigPin1,echoPin1);
  distance2=getDistance(trigPin2,echoPin2);
  //if(distance2>15 &&(count1==0)){
  //  lcd.setCursor(0, 0);
  //  lcd.print("Filtered Water is Empty");
  //  delay(2000);
  //}
  if(distance2>15 &&(count1==1)){
    count1--;
    lcd.setCursor(0, 1);
    lcd.print("Water Level : ");
    lcd.print(waterlevel);
    delay(2000);
    lcd.clear();
    lcd.setCursor(0, 1);
    lcd.print("Filtered Water");
    lcd.setCursor(11, 2);
    lcd.print("is Empty");
    delay(2000);
    lcd.clear();
  }
  while(distance1<5 && distance1>2 && (count1==1)&& distance2<16){
    triggerBuzzer();
    lcd.clear();
    lcd.setCursor(4, 1);
    lcd.print("Cup is near.");
    digitalWrite(relayPin4, HIGH); 
    
    distance1 = getDistance(trigPin1,echoPin1);
    distance2 = getDistance(trigPin2,echoPin2);
    lcd.setCursor(0, 1);
    lcd.print("Water Level : ");
    waterlevel=-distance2*0.11 + 1.72;
    if(waterlevel<=0){
      waterlevel=0;
    }
    lcd.print(waterlevel);
    lcd.print("L");
  }

  while(count1!=1){
  lcd.setCursor(6, 1);
  lcd.print("BLUEAQUA");
  delay(2000);
  lcd.clear();
  if(distance2<15){
    count1=1;
    lcd.setCursor(3, 1);
    lcd.print("Filtered Water");
    lcd.setCursor(4, 2);
    lcd.print("is Available");
    delay(2500);
    lcd.clear();
    lcd.setCursor(4, 1);
    lcd.print("Move the cup");
    lcd.setCursor(5, 2);
    lcd.print("to the tap");
    delay(2500);
    lcd.clear();
    break;
  }
  while(!isWaterLevelHigh()){
    lcd.setCursor(0, 0);
    lcd.print("Fill Water Till You");
    lcd.setCursor(2, 1);
    lcd.print("Hear the Buzzer");
    lcd.setCursor(1, 2);
    lcd.print("Sound(1.50L limit)");
  }

  lcd.clear();
  triggerBuzzer();
  lcd.setCursor(4, 1);
  lcd.print("Stop Filling");
  lcd.setCursor(7, 2);
  lcd.print("Now...");
  delay(3000);
  lcd.clear();
  lcd.setCursor(5, 1);
  lcd.print("Wait for a");
  lcd.setCursor(3, 2);
  lcd.print("few seconds...");
  delay(3000);
  lcd.clear();
  lcd.setCursor(0, 1);
  lcd.print("Checking");
  lcd.setCursor(8, 2);
  lcd.print("Parameters..");
  delay(5000);
  lcd.clear();
  int count3;
  lcd.setCursor(0, 1);
  lcd.print("Wait for 1 minute...");
  delay(5000);
  lcd.clear();

  float tdsValue = getTdsValue();
  float pHValue = getpHValue();
  float temperature = getTemperature();
  float clearness = getTurbidity();

  for(count3=0;count3<20;count3++){
     tdsValue = getTdsValue();
     pHValue = getpHValue();
     temperature = getTemperature();
     clearness = getTurbidity();
    
    lcd.setCursor(0, 0);
    lcd.print("TDS value: ");
    lcd.print(tdsValue);
    lcd.print("ppm");

    lcd.setCursor(0, 1);
    lcd.print("pH value: ");
    lcd.print(pHValue);
    lcd.print(" pH");

    lcd.setCursor(0, 2);
    lcd.print("Temperature:");
    lcd.print(temperature);
    lcd.print("C");

    lcd.setCursor(0, 3);
    lcd.print("Clearness:");
    lcd.print(clearness);
    lcd.print("%");
    delay(1000);
  }
  int count=0;
  lcd.clear();
  while(!(tdsCheck(tdsValue) & pHCheck(pHValue) & tempCheck(temperature) & turbCheck(clearness))){
    if(count==2){
      break;
    }
    lcd.setCursor(0, 1);
    lcd.print("Filtering........");
    triggerRelay(relayPin1, 20000);
    triggerRelay(relayPin1, 15000);
    while(!isWaterLevelHigh()){
      digitalWrite(relayPin5, HIGH);
    }
    digitalWrite(relayPin5, LOW);
    lcd.clear();
    
    lcd.setCursor(0, 0);
    lcd.print("Checking");
    lcd.setCursor(5, 1);
    lcd.print("Parameters");
    lcd.setCursor(10, 2);
    lcd.print("Again.....");
    delay(5000);
    lcd.clear();
    int count4;
    for(count4=0;count4<20;count4++){
      tdsValue = getTdsValue();
      pHValue = getpHValue();
      temperature = getTemperature();
      clearness = getTurbidity();

      lcd.setCursor(0, 0);
      lcd.print("TDS value: ");
      lcd.print(tdsValue);
      lcd.print("ppm");

      lcd.setCursor(0, 1);
      lcd.print("pH value: ");
      lcd.print(pHValue);
      lcd.print(" pH");

      lcd.setCursor(0, 2);
      lcd.print("Temperature:");
      lcd.print(temperature);
      lcd.print("C");

      lcd.setCursor(0, 3);
      lcd.print("Clearness:");
      lcd.print(clearness);
      lcd.print("%");
      delay(1000);
      lcd.clear();
      }
      
      count++;
}
  if(count==2){
    lcd.setCursor(0, 1);
    lcd.print("Cannot be filtered..");
    delay(3000);
    lcd.clear();
        int count5=30;
        while(count5>=0){
        lcd.setCursor(0, 0);
        lcd.print("Prepare for");
        lcd.setCursor(9, 1);
        lcd.print("Waste Water");
        lcd.setCursor(5, 3);
        lcd.print(count5);
        lcd.setCursor(7, 3);
        lcd.print(" seconds");
        delay(1000);
        lcd.clear();
        count5--;
        }
        lcd.setCursor(0, 1);
        lcd.print("Moving Out");
        lcd.setCursor(9, 2);
        lcd.print("Waste Water");
        delay(5000);
        lcd.clear();
        triggerRelay(relayPin3,20000);
        triggerRelay(relayPin3,15000);
        break;

      }
  if(count<2){
  lcd.setCursor(0, 1);
  lcd.print("Water is in");
  lcd.setCursor(3, 2);
  lcd.print("Optimum Condition");
  delay(5000);
  lcd.clear();
  lcd.setCursor(1, 1);
  lcd.print("Sending the Water");
  lcd.setCursor(5, 2);
  lcd.print("to Storage");
  delay(5000);
  lcd.clear();
  digitalWrite(relayPin2, HIGH);
  delay(20000);
  digitalWrite(relayPin2,LOW);
  lcd.setCursor(4, 1);
  lcd.print("Move the cup");
  lcd.setCursor(5, 2);
  lcd.print("to the tap");
  delay(5000);
  count1++;
  }
  }
  digitalWrite(relayPin4, LOW);
  
  
}

float getTemperature(){
  sensors.requestTemperatures();
  float temperature = sensors.getTempCByIndex(0);
  return temperature;
}

bool isWaterLevelHigh(){
  buttonState = digitalRead(floatSwitchPin);
  return buttonState;           //Read the float switch status and return
}

float getDistance(int trigPin, int echoPin){
  long duration;
  float distance;
  digitalWrite(trigPin, LOW);                   //Clears the trigPin
  delayMicroseconds(2);                         //Wait for 2 micro seconds
  digitalWrite(trigPin, HIGH);                  //Sets the trigPin on HIGH state for 10 micro seconds
  delayMicroseconds(10);                        //Wait for 10 micro seconds
  digitalWrite(trigPin, LOW);                   //Sets the trigPin on LOW state
  duration = pulseIn(echoPin, HIGH);            //Reads the echoPin, returns the sound wave travel time in microseconds
  distance = duration * 0.034 / 2;              //Calculating the distance in centi meters
  return distance;
}

float getTurbidity(){
  float voltage=0;
  for(int i=0; i<800; i++){
  int sensorValue = analogRead(A0);
  voltage += sensorValue * (5.0 / 1024.0);
  }
  voltage=voltage/800;
  if(voltage<2){
    voltage=2.00;
  }else if(voltage>3.5){
    voltage=3.50;
  }
  float clear=66.67*voltage-133.33;   // 71.43               142.86
  return clear;
}


float getTdsValue(){
  float temperature = getTemperature();
  float tdsValue;
  gravityTds.setTemperature(temperature);        //set the temperature and execute temperature compensation
  gravityTds.update();                           //sample and calculate
  tdsValue = gravityTds.getTdsValue();           //then get the value 
  if(tdsValue<50){
    tdsValue=tdsValue+50;
  }
  return tdsValue;
}

float getpHValue(){
  float Voltage;
  for(int i=0; i<800; i++){
  Voltage += analogRead(pHSensorPin) * (5.0 / 1023.0); 
  }
  Voltage=Voltage/800;
  float pHValue = -5.85*Voltage + 21.10;
  return pHValue;
}

void triggerRelay(int relayPin, int time){
  digitalWrite(relayPin, HIGH);                   //Turn on the relay to activate the motor
  delay(time);                                    //Wait for 2 seconds
  digitalWrite(relayPin, LOW);                    //Turn off the relay to deactivate the motor
}

void triggerBuzzer(){
  tone(buzzerPin, 1000);                         //Use a frequency of 1000Hz
  delay(1000);                                   //Play the tone for 1 second
  noTone(buzzerPin);                             //Stop the tone
}

bool tdsCheck(float tdsValue){
  if(tdsValue>50 && tdsValue<400){
    lcd.setCursor(0, 1);
    lcd.print("TDS is in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return true;
  }else{
    lcd.setCursor(0, 1);
    lcd.print("TDS is not in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return false;
  }
}

bool pHCheck(float pHValue){
  if(pHValue<9.5 && pHValue>6){
    lcd.setCursor(0, 1);
    lcd.print("pH is in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return true;
  }else{
    lcd.setCursor(0, 1);
    lcd.print("pH is not in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return false;
  }
}

bool tempCheck(float temperature){
  if(temperature<35 && temperature>15){
    lcd.setCursor(0, 1);
    lcd.print("Temperature is in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return true;
  }else{
    lcd.setCursor(0, 1);
    lcd.print("Temperature is not in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return false;
  }
}

bool turbCheck(float clear){
  if(clear>75){
    lcd.setCursor(0, 1);
    lcd.print("Clearness is in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return true;
  }else{
    lcd.setCursor(0, 1);
    lcd.print("Clearness is not in");
    lcd.setCursor(4, 2);
    lcd.print("Acceptable Range");
    delay(2000);
    lcd.clear();
    return false;
  }
}