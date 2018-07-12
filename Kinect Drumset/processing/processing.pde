/*-----------------------------------------------------------
Created by: Leonardo Merza
Version: 3.5
Date: 04/24/14

-----Revisions/Notes-----
v3.5
-fixed drum coordinates

v3.4
-added new coordinates for all drums

v3.2
-added confidence display to console
-got rid of z axis temporarily to find new ones
-might add height requirement to trigger true drum hit
-need new background
-setup new coordinates for drums with fixed z-axis length
-get kick drum and high hat pressure sensors working for integration with serial port
-add mixed drum sounds after getting everything else working
-----------------------------------------------------------*/

/**----------------------------------------------------------
Classes to import.
-----------------------------------------------------------*/
import SimpleOpenNI.*; 
import ddf.minim.*;

/**----------------------------------------------------------
Variables.
-----------------------------------------------------------*/
// Vector values for hands
PVector SKEL_LEFT_HAND = new PVector();
PVector SKEL_RIGHT_HAND = new PVector();
PVector SKEL_RIGHT_KNEE = new PVector();
PVector SKEL_LEFT_FOOT = new PVector();
PVector SKEL_RIGHT_FOOT = new PVector();

// XYZ coordinates of hands
float SKEL_LEFT_HANDX;
float SKEL_LEFT_HANDY;
float SKEL_LEFT_HANDZ;
float SKEL_RIGHT_HANDX;
float SKEL_RIGHT_HANDY;
float SKEL_RIGHT_HANDZ;
float SKEL_RIGHT_KNEEX;
float SKEL_RIGHT_KNEEY;
float SKEL_RIGHT_KNEEZ;
float SKEL_LEFT_FOOTX;
float SKEL_LEFT_FOOTY;
float SKEL_LEFT_FOOTZ;
float SKEL_RIGHT_FOOTX;
float SKEL_RIGHT_FOOTY;
float SKEL_RIGHT_FOOTZ;

// boolean values of drum hits
int numberOfDrums = 9;

// check to see if drum is already hit so they 
// aren't hit again until user moves hand away
boolean[] hitLeft = new boolean[numberOfDrums];
boolean[] hitRight = new boolean[numberOfDrums];

// xyz coordinates of all drums
int[] minX = new int[numberOfDrums];
int[] minY = new int[numberOfDrums];
int[] maxX = new int[numberOfDrums];
int[] maxY = new int[numberOfDrums];
int[] minZ = new int[numberOfDrums];
int[] maxZ = new int[numberOfDrums];

// Size of drawn dot on each joint  
float dotSize = 20;
// Vector to scalar ratio
float vectorScalar = 525;

// Image variables
PImage img;
PImage kinectRGB;

// Kinect object to interact with kinect
SimpleOpenNI kinect;

// Audio player variables
Minim m;
AudioPlayer[] drumSounds= new AudioPlayer[numberOfDrums];

// threshold of level of confidence
float confidenceLevel = 0.1;
// the current confidence level that the kinect is tracking
float confidence;
// vector of tracked head for confidence checking
PVector confidenceVector = new PVector();

// boolean if kinect is tracking
boolean tracking = false;
// current userid of tracked user
int userID;
// mapping of users
int[] userMapping;
// background image
PImage backgroundImage;
// image from rgb camera
PImage rgbImage;

/**----------------------------------------------------------
Setup method. Sets up kinect and draw window. Loads image
and audio player.
-----------------------------------------------------------*/
void setup() 
{ 
  // set proximity variables
  
  // high hat
  minX[1] = 150;
  maxX[1] = 190;
  minY[1] = 260;
  maxY[1] = 280;
  minZ[1] = 1700;
  maxZ[1] = 2000;
  
  // bottom right drum
  minX[2] = 360;
  maxX[2] = 520;
  minY[2] = 320;
  maxY[2] = 370;
  minZ[2] = 1800;
  maxZ[2] = 2000;
  
  // snare drum
  minX[3] = 200;
  maxX[3] = 260;
  minY[3] = 320;
  maxY[3] = 370;
  minZ[3] = 1800;
  maxZ[3] = 2000;
  
  // top left drum
  minX[4] = 240;
  maxX[4] = 300;
  minY[4] = 270;
  maxY[4] = 300;
  minZ[4] = 1800;
  maxZ[4] = 2000;
  
  // top right drum
  minX[5] = 320;
  maxX[5] = 380;
  minY[5] = 270;
  maxY[5] = 300;
  minZ[5] = 1800;
  maxZ[5] = 2000;

  // left crash
  minX[6] = 190;
  maxX[6] = 260;
  minY[6] = 190;
  maxY[6] = 250;
  minZ[6] = 1600;
  maxZ[6] = 1800;
  
  // center crash
  minX[7] = 270;
  maxX[7] = 340;
  minY[7] = 190;
  maxY[7] = 230;
  minZ[7] = 1600;
  maxZ[7] = 1800;
  
  // right crash
  minX[8] = 350;
  maxX[8] = 450;
  minY[8] = 190;
  maxY[8] = 250;
  minZ[8] = 1600;
  maxZ[8] = 1800;
  
  // set all booleans to false for left/right hands
  for(int i=0;i<numberOfDrums;i++) {
    hitLeft[i] = false;
  } // for(int i=0;i<hitLeft.length();i++)
  for(int i=0;i<numberOfDrums;i++) {
    hitRight[i] = false;
  } // for(int i=0;i<hitLeft.length();i++)

  // create a new kinect object
  kinect = new SimpleOpenNI(this); 
  // mirrors image of kinect to get natural mirror effect
  kinect.setMirror(true); 
  // enable depthMap generation 
  kinect.enableDepth(); 
  // enable rgb sensor
  kinect.enableRGB();
  // enable skeleton generation for joints
  kinect.enableUser();

  // create a window the size of the depth information
  size(kinect.depthWidth(), kinect.depthHeight()); 
  // window background color
  background(200,0,0);
  // drawer color is red
  stroke(255,0,0);
  // thickness of drawer is small
  strokeWeight(1);
  // smooth out drawer
  smooth();
  
  // load image
  img = loadImage("drumset.png");
  // load sound player
  m = new Minim(this);
  
  // load sounds into AudioPlayer array
  drumSounds[0] = m.loadFile("kickDrum.wav");
  drumSounds[1] = m.loadFile("hihatDrum.wav");
  drumSounds[2] = m.loadFile("rightBottomDrum.wav");
  drumSounds[3] = m.loadFile("snareDrum.wav");
  drumSounds[4] = m.loadFile("leftTopDrum.wav");
  drumSounds[5] = m.loadFile("rightTopDrum.wav");
  drumSounds[6] = m.loadFile("leftCrashDrum.wav");
  drumSounds[7] = m.loadFile("centerCrashDrum.wav");
  drumSounds[8] = m.loadFile("rightCrashDrum.wav");
  
   // turn on depth-color alignment
  kinect.alternativeViewPointDepthToImage(); 

  // load the background image
  backgroundImage = loadImage("qwe.jpg"); 
  
} // void setup()
  
/**----------------------------------------------------------
Draw Method. Loops forever.  Updates kinect cameras amd
draws image in window.  If kinect is tracking then get
coordinates of hands and prints them.  Checks to see if
user hands are in range of drums.
-----------------------------------------------------------*/
void draw() 
{ 
  // display the background image first at (0,0)
  image(backgroundImage, 0, 0);
  
  //update kinect camera
  kinect.update(); 
  //get rgb and depth data
   
// get the Kinect color image
  rgbImage = kinect.rgbImage(); 
  // prepare the color pixels
  loadPixels();
  // get pixels for the user tracked
  userMapping = kinect.userMap();
    
  // for the length of the pixels tracked, color them
  // in with the rgb camera
  for (int i =0; i < userMapping.length; i++) {
    // if the pixel is part of the user
    if (userMapping[i] != 0) {
      // set the sketch pixel to the rgb camera pixel
      pixels[i] = rgbImage.pixels[i]; 
    } // if (userMap[i] != 0)
  } // (int i =0; i < userMap.length; i++)
   
  // update any changed pixels
  updatePixels();
  
  //draw drum image at coordinates (100,200)
  image(img,100,200);
  
  int[] userList = kinect.getUsers();
  
 for(int i=0;i<userList.length;i++)
  {
    // if kinect is tracking ceratin user then get joint vectors
    if(kinect.isTrackingSkeleton(userList[i]))
    {
      // get condidence level that kinect is tracking hip
      confidence = kinect.getJointPositionSkeleton(userList[i],
                          SimpleOpenNI.SKEL_RIGHT_KNEE,confidenceVector);
                          
      // display confidence interval
      println("Confidence Interval: " + confidence);
      
      // if confidence of tracking is beyond threshold, then track user
      if(confidence > confidenceLevel)
      {
        getCoordinates(userList[i]);
        printHandCoordinates();
      
      //check each drum to see if hands are in proximity
        for(int j=1;j<9;j++)
        {
          print(j);
          checkDrums(j);
        } // for(int j=1;j<9;j++)
        
      } // if(confidence > confidenceLevel)
    } // if(kinect.isTrackingSkeleton(userList[i]))
  } // for(int i=0;i<userList.length;i++)
  
} // void draw() 

/*---------------------------------------------------------------
When a new user is found, print new user detected along with
userID and start pose detection.  Input is userID
----------------------------------------------------------------*/
void onNewUser(SimpleOpenNI curContext, int userId){
  println("New User Detected - userId: " + userId);
  // start tracking of user id
  curContext.startTrackingSkeleton(userId);
} //void onNewUser(SimpleOpenNI curContext, int userId)
   
/*---------------------------------------------------------------
Print when user is lost. Input is int userId of user lost
----------------------------------------------------------------*/
void onLostUser(SimpleOpenNI curContext, int userId){
  // print user lost and user id
  println("User Lost - userId: " + userId);
} //void onLostUser(SimpleOpenNI curContext, int userId)


/**----------------------------------------------------------
Gets XYZ coordinates of tracked hands. Input is user ID.
-----------------------------------------------------------*/ 
void getCoordinates(int userID) 
{
  // get postion of hands
  kinect.getJointPositionSkeleton(userID,SimpleOpenNI.SKEL_LEFT_HAND,SKEL_LEFT_HAND);
  kinect.getJointPositionSkeleton(userID,SimpleOpenNI.SKEL_RIGHT_HAND,SKEL_RIGHT_HAND);
  kinect.getJointPositionSkeleton(userID,SimpleOpenNI.SKEL_RIGHT_KNEE,SKEL_RIGHT_KNEE);
  kinect.getJointPositionSkeleton(userID,SimpleOpenNI.SKEL_RIGHT_FOOT,SKEL_RIGHT_FOOT);
  kinect.getJointPositionSkeleton(userID,SimpleOpenNI.SKEL_LEFT_FOOT,SKEL_LEFT_FOOT);

  // convert real world point to projective space
  kinect.convertRealWorldToProjective(SKEL_LEFT_HAND,SKEL_LEFT_HAND);
  kinect.convertRealWorldToProjective(SKEL_RIGHT_HAND,SKEL_RIGHT_HAND);
  kinect.convertRealWorldToProjective(SKEL_RIGHT_KNEE,SKEL_RIGHT_KNEE);
  kinect.convertRealWorldToProjective(SKEL_RIGHT_FOOT,SKEL_RIGHT_FOOT);
  kinect.convertRealWorldToProjective(SKEL_LEFT_FOOT,SKEL_LEFT_FOOT);

  // scale z vector of each joint to scalar form
  SKEL_LEFT_HANDX = (vectorScalar/SKEL_LEFT_HAND.x);
  SKEL_RIGHT_HANDX = (vectorScalar/SKEL_RIGHT_HAND.x);
  SKEL_LEFT_HANDY = (vectorScalar/SKEL_LEFT_HAND.y);
  SKEL_RIGHT_HANDY = (vectorScalar/SKEL_RIGHT_HAND.y);
  SKEL_LEFT_HANDZ = (vectorScalar/SKEL_LEFT_HAND.z);
  SKEL_RIGHT_HANDZ = (vectorScalar/SKEL_RIGHT_HAND.z);
  SKEL_RIGHT_KNEEX = (vectorScalar/SKEL_RIGHT_KNEE.x);
  SKEL_RIGHT_KNEEY = (vectorScalar/SKEL_RIGHT_KNEE.y);
  SKEL_RIGHT_KNEEZ = (vectorScalar/SKEL_RIGHT_KNEE.z);
  SKEL_LEFT_FOOTX = (vectorScalar/SKEL_LEFT_FOOT.x);
  SKEL_LEFT_FOOTY = (vectorScalar/SKEL_LEFT_FOOT.y);
  SKEL_LEFT_FOOTZ = (vectorScalar/SKEL_LEFT_FOOT.z);
  SKEL_RIGHT_FOOTX = (vectorScalar/SKEL_RIGHT_FOOT.x);
  SKEL_RIGHT_FOOTY = (vectorScalar/SKEL_RIGHT_FOOT.y);
  SKEL_RIGHT_FOOTZ = (vectorScalar/SKEL_RIGHT_FOOT.z);
  
  // fill  the dot color as red
  fill(255,0,0); 
  ellipse(SKEL_LEFT_HAND.x,SKEL_LEFT_HAND.y, SKEL_LEFT_HANDZ*dotSize,SKEL_LEFT_HANDZ*dotSize);
  ellipse(SKEL_RIGHT_HAND.x,SKEL_RIGHT_HAND.y, SKEL_RIGHT_HANDZ*dotSize,SKEL_RIGHT_HANDZ*dotSize);

} // void getCoordinates()

/*-----------------------------------------------------------
Prints XYZ coordinates to serial monitor. For debugging.
-----------------------------------------------------------*/
void printHandCoordinates()
{
  println("Left hand XYZ: " + SKEL_LEFT_HAND.x + " " + SKEL_LEFT_HAND.y + " "
          + SKEL_LEFT_HAND.z);
  println("right hand XYZ: " + SKEL_RIGHT_HAND.x + " " + SKEL_RIGHT_HAND.y + " "
          + SKEL_RIGHT_HAND.z);
  println("right foot XYZ: " + SKEL_RIGHT_FOOT.x + " " + SKEL_RIGHT_FOOT.y + " "
          + SKEL_RIGHT_FOOT.z);
  println("left foot XYZ: " + SKEL_LEFT_FOOT.x + " " + SKEL_LEFT_FOOT.y + " "
          + SKEL_LEFT_FOOT.z);
} // void getHandCoordinates()  

/*-----------------------------------------------------------
Method input is an int of the type of drum.  Checks each hand
to make sure they are above drum to make noise.  Also make
sure noise only happens once until user lifts hands back up.
-----------------------------------------------------------*/ 
void checkDrums(int i)
{
  
    if(SKEL_LEFT_HAND.y < minY[i]) // maybe add extra hieght to make sure hand is high enough?
    {
      hitLeft[i] = false;
    } // if left hand is above drum then allow hit
    
    if(SKEL_RIGHT_HAND.y < minY[i])
    {
      hitRight[i] = false;
    } // if right hand is above drum then allow hit
    
    if(SKEL_LEFT_HAND.x > minX[i] & SKEL_LEFT_HAND.x < maxX[i]
    & SKEL_LEFT_HAND.y > minY[i] & SKEL_LEFT_HAND.y < maxY[i]
    & SKEL_LEFT_HAND.z > minZ[i] & SKEL_LEFT_HAND.z < maxZ[i]
    & !(hitLeft[i]))
    {
        // play the file
        drumSounds[i].play();
        drumSounds[i].rewind();
        hitLeft[i] = true;
    } // if left hand is in drum box then try to make noise
   
    if(SKEL_RIGHT_HAND.x > minX[i] & SKEL_RIGHT_HAND.x < maxX[i]
    & SKEL_RIGHT_HAND.y > minY[i] & SKEL_RIGHT_HAND.y < maxY[i]
    & SKEL_RIGHT_HAND.z > minZ[i] & SKEL_RIGHT_HAND.z < maxZ[i]
    & !(hitRight[i]))
    {
        // play the file
        drumSounds[i].play();
        drumSounds[i].rewind();
        hitRight[i] = true;
    } // if right hand is in drum box then try to make noise
} // void checkDrums(int i)
