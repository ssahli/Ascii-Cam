//
//  CamView.m
//  ASCII Cam
//

#import "CamView.h"
#include <OpenGL/gl.h>

@implementation CamView

@synthesize videoDataOutput;



#pragma mark - Initialization



// The object is initialized automatically through the nib--instead init procedures are done here
- (void)awakeFromNib
{
    // Create the video data output to capture individual frames
    videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
}

// Set up shaders and texture
- (void)prepareOpenGL
{
    // Obtain and compile shaders
    GLuint vertexShader = [self compileShader:@"Vertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"ASCIIFilter" withType:GL_FRAGMENT_SHADER];
    
    // Create program and attach shaders
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    
    // Check for successful link with the shaders
    GLint success;
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (success == GL_FALSE)
    {
        GLchar messages[256];
        glGetProgramInfoLog(shaderProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
    }
    
    [self initTextures];
    
    glUseProgram(shaderProgram);
}

// Load the texture
- (void)initTextures
{
    // Load image and convert to bitmap
    NSImage *image = [NSImage imageNamed:@"ascii.png"];
    [image lockFocus];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [image size].width, [image size].height)];
    [image unlockFocus];
    
    // Create ascii texture 
    glGenTextures(1, &asciiTexture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, asciiTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)[bitmap pixelsWide], (int)[bitmap pixelsHigh], 0, GL_BGRA, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
}

// Compile a shader
- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    // Load the GLSL shader as a string and create a GL shader object
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    GLuint shaderObject = glCreateShader(shaderType);
    
    // Compile the shader object with the GLSL shader
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderObject, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shaderObject);
    
    // Check for successful compile
    GLint success;
    glGetShaderiv(shaderObject, GL_COMPILE_STATUS, &success);
    if (success == GL_FALSE)
    {
        GLchar messages[256];
        glGetShaderInfoLog(shaderObject, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
    }
    
    return shaderObject;
}



#pragma mark - Frame Processing



// Delegate method to capture the video output frames
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // Get the pixel information and render the screen
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self drawFrame:pixelBuffer];
}

// Draws the screen by converting the pixel buffer to a GL texture to be rendered
- (void)drawFrame:(CVImageBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int textureWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int textureHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    // Generate a GL texture for rendering
    glGenTextures(1, &cameraTexture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, cameraTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
  
    // Prepare for render
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Pass textures to shaders
    glUniform1i(glGetUniformLocation(shaderProgram, "asciiTexture"), 0);
    glUniform1i(glGetUniformLocation(shaderProgram, "cameraTexture"), 1);
    
    // Draw the vertices of the rectangle and the camera texture. Equivalent to the bounds of the view
    glBegin(GL_QUADS);
    {
        // Lower-right
        glTexCoord2f(0, 1);
        glVertex2f(1, -1);
        
        // Lower-left
        glTexCoord2f(1, 1);
        glVertex2f(-1, -1);
        
        // Upper-left
        glTexCoord2f(1, 0);
        glVertex2f(-1, 1);
        
        // Upper-right
        glTexCoord2f(0, 0);
        glVertex2f(1, 1);
    }
    glEnd();
    
    // Clean-up after the render
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    glFlush();
    glDeleteTextures(1, &cameraTexture);
}


@end
