


import processing.serial.*;
import twitter4j.conf.*;
import twitter4j.api.*;
import twitter4j.*;

import gab.opencv.*;
import gab.opencv.Flow;
import java.awt.Rectangle;

import javax.imageio.*;
import javax.imageio.stream.*;
import java.awt.image.BufferedImage;

import processing.video.*;

ConfigurationBuilder  cb;
Twitter twitter;

int numeroRaro =0;


Capture video;
OpenCV opencv;

Timer timer;        // Timer object
Timer timer2;   

String currentFormat = "png";

int d = day();    
int mm = month();  
int y = year();   

int s = second(); 
int m = minute();  
int h = hour(); 

int posX;
int posY;

boolean capturaActiva = true;
boolean consultaXML = true;
//area donde capturar


int areaLeft=0;
int areaRight=0;

//area donde tagear
int areaTaggingTop=0;
int areaTaggingBottom=0;

//minimo tamaño ancho alto para capturar
int minWidth=0;
int minHeight=0;

//data

XML xml;
String vuelo="";

String recorte1="";
String recorte2="";

String numVuelo ="IB2314";

void setup() {
  
  size(1024, 768);
  
  ConfigurationBuilder cbs = new ConfigurationBuilder();

  //permisos para hacer el tweet
  cbs.setOAuthConsumerKey("xxx");
  cbs.setOAuthConsumerSecret("xxx");
  cbs.setOAuthAccessToken("xx-xxx");
  cbs.setOAuthAccessTokenSecret("xxxx");

  TwitterFactory tf = new TwitterFactory(cbs.build());
  twitter = tf.getInstance();
  
  
  String[] cameras = Capture.list();
  
  minWidth =12;
  minHeight =5;
  
  //espacio donde hace la captura
  areaLeft = 360;
  areaRight = 840;
  
  //espacio donde hace el tagging
  areaTaggingTop=0;
  areaTaggingBottom=640;
  
  //tiempo que dura el timer
  timer = new Timer(12000);    
  timer2 = new Timer(12000);  
  //timer.start();    
  
   if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    } else {
      println("Available cameras:");
      for (int i = 0; i < cameras.length; i++) {
        
        //Hay que sacar la lista de configuraciones y elegir 1.
        println(cameras[i]+" // "+i);
      }
      
    }
 
  //video = new Movie(this, "street.mov");
  video = new Capture(this,  1024, 768,cameras[0]);
  //video = new Capture(this, cameras[20]);
  opencv = new OpenCV(this, 1024, 768);
  
  opencv.startBackgroundSubtraction(5, 3, 0.5);
  //opencv.startBackgroundSubtraction(100, 30, 0.0005);
  
  video.start();
 
}

void draw() {
  
 //println(consultaXML);
 //scale(2);
  
  if (timer.isFinished()) {
     capturaActiva = true;
    //timer.start();
  }

  if (timer2.isFinished()) { 
    consultaXML =true;

  }
 
  opencv.loadImage(video);

  opencv.equalizeHistogram();
  opencv.updateBackground();
  image(opencv.getOutput(),0,0);
  image(video,0,0);
  
  //video.filter(50);

  
  noFill();
  stroke(0, 255, 0);
  strokeWeight(1);
 
  /* 
  //Lectura del API de vuelos
  if(millis()-lastRecordedTime>interval){
        
  }  
  */
  
 
  for (Contour contour : opencv.findContours()) {

    h = hour(); 
    m = minute();  

    Rectangle r = contour.getBoundingBox();
    
    if(r.y > areaTaggingTop && r.y < areaTaggingBottom && h < 18 && m < 30 && h > 8) {
      
         
      
        //la zonda detectada tiene que tener un minio de anchura
        if(r.width > minWidth && r.height > minHeight) {
          
          stroke(255,255,255);
          rect(r.x-10, r.y-10, r.width+10, r.height+10);

          textSize(16);
          text("Vuelo"+numVuelo, posX, posY+25); 

          posX= r.x;
          posY= r.y;
          
          
           //leemos el xml
           if(consultaXML) {
             generadorDeVuelo();
             timer2.start();

          }
          
          
          //hacer captura
          if (r.x > areaLeft && r.x < areaRight && capturaActiva) {
       
            hacerCaptura();
            capturaActiva = false;
            timer.start();  
    
          }
          
          
      
        }
        
        
        
        
    }

  }
  


}

//funcion que crea el tweet
void post1Tweet(String numeroV, String urlv)
{
    try
    {
        Status status = twitter.updateStatus("Welcome passanger from flight "+numeroV+" Here a picture of you arriving to Barcelona: "+urlv);
        //Status status = twitter.updateStatus("Welcome passanger from flight http://www.audionlineteam.es/aviones/saved/14122016-100856-snapshot.png");
        
        System.out.println("Status updated to [" + status.getText() + "].");
    }
    catch (TwitterException te)
    {
        System.out.println("Error: "+ te.getMessage());
    }
    
    println("post1Tweet()");
}


void captureEvent(Capture c) {
  c.read();
}

void hacerCaptura() {
  
  s = second(); 
  m = minute();  
  h = hour(); 
  
  save("aviones/avion"+d+"-"+"-"+mm+"-"+y+"--"+h+"-"+m+"-"+s+".png");
  
  //save("avion"+d+m+y+"-"+h+m+s+".png");


  DataUpload du = new DataUpload();
  boolean bOK = false;
  
  // Upload the currently displayed image with a fixed name, and the chosen format
  if (currentFormat.equals("png"))
  {
    bOK = du.UploadImage("snapshot." + currentFormat, (BufferedImage) g.image);
    //println("BufferedImage: "+g.image);
  }
  else
  {
    // We need a new buffered image without the alpha channel
    BufferedImage imageNoAlpha = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
    loadPixels();
    imageNoAlpha.setRGB(0, 0, width, height, g.pixels, 0, width);
    bOK = du.UploadImage("snapshot." + currentFormat, imageNoAlpha);
  }
  
  if (!bOK)
    return; // Some problem on Java side. Do nothing

  // Get the answer of the PHP script
  int rc = du.GetResponseCode();
  String feedback = du.GetServerFeedback();
  println("----- " + rc + " -----\n" + feedback + "---------------");

  // Extract the URL of the image from the PHP feedback
  // I use the hard way, the script could just answer the right URL...
  //String[] m = match(feedback, "<img src='([^']+)'");
  
  post1Tweet(numVuelo,"http://www.audionlineteam.es/aviones/");
  

}


void keyPressed()
{
  
  if (key == 'j')
  {
    currentFormat = "jpg";
  }
  if (key == 'J')
  {
    currentFormat = "jpeg";
  }
  if (key == 'p')
  {
    currentFormat = "png";
  }
  if (key == 's')
  {

  }
  
  //float raro = random(1111,9999);
  //int r = int(raro);
  
  //post1Tweet(numVuelo,"http://www.audionlineteam.es/aviones/");
  //generadorDeVuelo();
  //timer2.start();
  hacerCaptura();

}


void generadorDeVuelo() {
  
  
  //xml = loadXML("https://api.flightstats.com/flex/flightstatus/rest/v2/xml/flightsNear/41.4175873/2.2654055/3?appId=d77ddf3e&appKey=c759a8b693b8fcaa48793a37354e81e4&maxFlights=5&sourceType=all");
  xml = loadXML("https://api.flightstats.com/flex/flightstatus/rest/v2/xml/flightsNear/41.4175873/2.2654055/8?appId=cfd13688&appKey=3112c7c9a9ddbae52834544850b804c0&maxFlights=1&sourceType=all");
  
  /*
  AppId:
  cfd13688
  
  AppKey:
  3112c7c9a9ddbae52834544850b804c0
  */
  
  XML[] children = xml.getChildren("flightPositions");

  // println(children.length);
  for (int i = 0; i < children.length; i++) {
     vuelo = children[i].getContent();  
     
  }
  
  
  if(vuelo!="") {
  
    recorte1 = vuelo.substring(9,16);
    numVuelo = recorte1;
    
  } else {
    
    float vueloRaro = random(1111,9999);
    int rv = int(vueloRaro);
    
    numVuelo = "AB" + rv;

  }

  consultaXML =false;
  
  println(numVuelo);
  println("generadorDeVuelo()");
  
}



class Timer {

  int savedTime; // This is when the timer is started
  int totalTime; // This is how long the timer should last

  Timer(int tempTotalTime) {
    totalTime = tempTotalTime;
  }

  // This command starts the timer
  void start() {
    // When the timer starts it stores the current time in milliseconds.
    savedTime = millis();
  }

  // The function isFinished() returns true if 5,000 ms have passed. 
  boolean isFinished() { 
    // This command checks how much time has passed
    int passedTime = millis()- savedTime;
    if (passedTime > totalTime) {
      return true;
    } else {
      return false;
    }
  }
}
