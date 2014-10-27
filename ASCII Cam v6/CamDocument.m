//
//  CamDocument.m
//  ASCII Cam
//

#import "CamDocument.h"

@interface CamDocument()

// Internal properties -- capture device
@property (retain) NSArray                  *videoDevices;
@property (assign) AVCaptureDevice          *selectedVideoDevice;
@property (retain) AVCaptureDeviceInput     *videoDeviceInput;

@end



@implementation CamDocument

@synthesize videoDeviceInput;
@synthesize view;

- (NSString *)windowNibName { return @"CamDocument"; }



#pragma mark - Initialization



// Create & configure session, add video device input
- (id)init
{
    self = [super init];
    if (self) {
        // Create session
        session = [[AVCaptureSession alloc] init];
        
        // Select a video input device and configure session
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (videoDevice)
            [self setSelectedVideoDevice:videoDevice];
        else
            [self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
    }
    return self;
}

// Stop the session
- (void)windowWillClose:(NSNotification *)notification { [session stopRunning]; }

// Once view has initialized, add the video data output and begin the session
- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    // Connect the session output and the view
    if ([view videoDataOutput])
        [session addOutput:[view videoDataOutput]];
    
    // Start the session
    [session startRunning];
}



#pragma mark - Video capture



// Get the video capture device
- (AVCaptureDevice *)selectedVideoDevice {
    return [videoDeviceInput device];
}

// Set the video capture device
- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    [session beginConfiguration];
    
    if (selectedVideoDevice) {
        NSError *error = nil;
        
        // Create a device input for the selected device and add it to the AV session
        AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice error:&error];
        if (newVideoDeviceInput == nil) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentError:error];
            });
        } else {
            [session addInput:newVideoDeviceInput];
            [self setVideoDeviceInput:newVideoDeviceInput];
        }
    }
    
    [session setSessionPreset:AVCaptureSessionPresetLow];
    [session commitConfiguration];
}

@end
