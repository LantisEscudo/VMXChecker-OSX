//
//  VMXCheckerController.h
//  VMXChecker
//
//  Created by User on 1/17/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegexKitLite.h"
#import "TaskWrapper.h"

@interface VMXCheckerController : NSObject <TaskWrapperController> {
    
    //Input Field
    IBOutlet NSTextField *inputFileBox;
    IBOutlet NSButton *browseButton;
    
    //Properties Labels
    IBOutlet NSTextField *videoPropertiesLabel;
    IBOutlet NSTextField *audioPropertiesLabel;
    
    //Other Controls
    IBOutlet NSTextField *messageLabel;
    IBOutlet NSButton *fixButton;
    
    //Processing Pane
    IBOutlet NSTextField *textLabel;
    IBOutlet NSPanel *encodePanel;
    IBOutlet NSButton *closePanelButton;
    IBOutlet NSTextView *textWindow;
    IBOutlet NSProgressIndicator *progBar;
    
    @private
    NSWindow *window;
    NSString* ffmpegpath;
    BOOL findRunning;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSString *ffmpegpath;

- (IBAction)fileBrowse:(id)sender;
- (IBAction)fixClick:(id)sender;
- (void)media_info;
- (void)check_file;


@end
