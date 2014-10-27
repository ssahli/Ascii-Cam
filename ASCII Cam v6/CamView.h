//
//  CamView.h
//  ASCII Cam
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface CamView : NSOpenGLView <AVCaptureVideoDataOutputSampleBufferDelegate>
{
@private
    GLuint          shaderProgram;
    GLuint          cameraTexture;
    GLuint          asciiTexture;
}

@property (retain) AVCaptureVideoDataOutput *videoDataOutput;

@end