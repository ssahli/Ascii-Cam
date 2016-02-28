//
//  CamDocument.m
//  ASCII Cam
//

#import "CamDocument.h"

@interface CamDocument()

@property (retain) NSArray                  *videoDevices;
@property (assign) AVCaptureDevice          *selectedVideoDevice;
@property (retain) AVCaptureDeviceInput     *videoDeviceInput;

@end





@implementation CamDocument

@synthesize videoDeviceInput;
@synthesize view;

- (NSString *)windowNibName { return @"CamDocument"; }



#pragma mark - Initialization



/*
    Initialize video capture session and add the video device input.
 */
- (id)init
{
    self = [super init];
    if (self) {
        /*
            Initialize video capture session
         */
        session = [[AVCaptureSession alloc] init];
        
        
        /*
            Find and add the video device input
         */
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (videoDevice)
            [self setSelectedVideoDevice:videoDevice];
        else
            [self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
    }
    return self;
}





/*
    When closing the window or exiting the application, end the video capture session.
 */
- (void)windowWillClose:(NSNotification *)notification { [session stopRunning]; }





/*
    Once the application's window finishes initialization, add the video data
    output and start the video capture session.
 */
- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    /*
        Connect the video capture session and the video data output
     */
    if ([view videoDataOutput])
        [session addOutput:[view videoDataOutput]];
    
    /*
        Start the video capture session
     */
    [session startRunning];
}



#pragma mark - Video capture



/*
    Get the video capture device
 */
- (AVCaptureDevice *)selectedVideoDevice {
    return [videoDeviceInput device];
}





/*
    Set the video capture device.
 */
- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    [session beginConfiguration];
    
    if (selectedVideoDevice) {
        NSError *error = nil;
        
        
        /*
            Initialize an input device for the selected device, and add it to the
            video capture session
         */
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
    
    
    /*
        Set a low quality preset for the video capture
     */
    [session setSessionPreset:AVCaptureSessionPresetLow];
    [session commitConfiguration];
}

@end
