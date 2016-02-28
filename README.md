Ascii-Cam
=========

ASCII-Cam is an OS X video application that transforms live video capture using a colored ASCII OpenGL shader. The intent behind writing this program was for me to familiarize myself with Objective-C, the Cocoa frameworks, and OpenGL. I had originally created this program without OpenGL, but the performance was (predictably) awful.

### File overview
  * CamDocument: the logic for setting up the camera, grabbing live feed, and sending the frames for rendering
  
  * CamView: includes all OpenGL logic, transforming the live feed and renders it back frame by frame
  
  * ASCIIFilter.glsl: the OpenGL shader prorgram that transforms an ordinary video frame to a colored ASCII frame
  
  * Vertex.glsl: an OpenGL shader program that simply defines the bounds of the viewport for rendering
  
  * ascii.png: an image of the ASCII characters used in ASCIIFilter.glsl. If you decide to change this, a few things in ASCIIFilter.glsl will require changing as well. See below for details.
