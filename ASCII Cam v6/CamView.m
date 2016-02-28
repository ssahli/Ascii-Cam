//
//  CamView.m
//  ASCII Cam
//

#import "CamView.h"
#include <OpenGL/gl.h>

@implementation CamView

@synthesize videoDataOutput;



#pragma mark - Initialization



/*
    This object is automatically initialized through the nib;
    instead, init procedures are performed here.
 */
- (void)awakeFromNib
{
    /*
        Create the video data output to capture individual frames.
        In case computation takes too long to keep up with video input,
        drop any frames that are coming in late.
     */
    videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
}





/*
    Start up OpenGL and the required shaders.
 */
- (void)prepareOpenGL
{
    /*
        Compile the required shaders
     */
    GLuint vertexShader = [self compileShader:@"Vertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"ASCIIFilter" withType:GL_FRAGMENT_SHADER];
    
    
    /*
        Attach the shaders to a new program.
     */
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    
    
    /*
        Verify that the shader programs were correctly linked
        to the OpenGL render pipeline.
     */
    GLint success;
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (success == GL_FALSE)
    {
        GLchar messages[256];
        glGetProgramInfoLog(shaderProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
    }
    
    
    /*
        Initialize the incoming textures and begin the shader program.
     */
    [self initTextures];
    glUseProgram(shaderProgram);
}






/*
    Load the ASCII characters png file, convert to a bitmap, and create
    an OpenGL texture from it to be used in the shader program.
 */
- (void)initTextures
{
    /*
        Load the ASCII png image and convert to a bitmap
     */
    NSImage *image = [NSImage imageNamed:@"ascii.png"];
    [image lockFocus];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [image size].width, [image size].height)];
    [image unlockFocus];
    
    
    /*
        Create an OpenGL texture from the bitmap
     */
    glGenTextures(1, &asciiTexture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, asciiTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)[bitmap pixelsWide], (int)[bitmap pixelsHigh], 0, GL_BGRA, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
}






/*
    Compile a shader for use in the OpenGL shader program.
 */
- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    /*
        Load the shader and create an OpenGL shader object
     */
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    GLuint shaderObject = glCreateShader(shaderType);
    
    
    /*
        Compile the shader object with the GLSL shader
     */
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderObject, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shaderObject);
    
    
    /*
        Verify that the shader object compiled without errors
     */
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



/*
    Delegate function that captures the frames from the video output
    as they come.
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    /*
        Get the pixel information and render to screen
     */
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self drawFrame:pixelBuffer];
}






/*
    Render the screen by converting the incoming pixel buffer to a renderable
    OpenGL texture.
 */
- (void)drawFrame:(CVImageBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int textureWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int textureHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    /*
        Generate an OpenGL texture for rendering
     */
    glGenTextures(1, &cameraTexture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, cameraTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
    
    
    /*
        Clear the current buffer to prepare a new rendered frame
     */
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    /*
        Pass the textures to the shader program
     */
    glUniform1i(glGetUniformLocation(shaderProgram, "asciiTexture"), 0);
    glUniform1i(glGetUniformLocation(shaderProgram, "cameraTexture"), 1);
    
    
    /*
        Render the viewport and camera texture. This is the bounds of the application's view.
     */
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
    
    
    /*
        Post-render clean-up.
     */
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    glFlush();
    glDeleteTextures(1, &cameraTexture);
}


@end
