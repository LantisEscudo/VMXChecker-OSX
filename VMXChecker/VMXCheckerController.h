//
//  VMXCheckerController.h
//  VMXChecker
//
/*
 This software is licensed under the MIT License:
 
 Copyright (C) 2013 Michael Montanye
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

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
    IBOutlet NSTextField *progressLabel;
    IBOutlet NSTextField *fpsLabel;
    IBOutlet NSTextField *framesLabel;
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
- (IBAction)cancelClick:(id)sender;
- (void)media_info;
- (void)check_file;
- (void)reset_fields;
- (void)encode;
- (NSArray*)newCommandLine;


@end
