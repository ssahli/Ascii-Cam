//
//  CamDocument.h
//  ASCII Cam
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#include "CamView.h"

@interface CamDocument : NSDocument 
{
@private
    CamView                     *view;
    AVCaptureSession            *session;
}

@property (strong) IBOutlet CamView *view;

@end
