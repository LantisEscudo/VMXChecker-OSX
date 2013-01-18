//
//  VMXCheckerController.m
//  VMXChecker
//
//  Created by User on 1/17/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "VMXCheckerController.h"

@implementation VMXCheckerController

TaskWrapper* encodeTask;
int passes;
int passes_done;


@synthesize window;
@synthesize ffmpegpath;

- (void) awakeFromNib {
    //Code for startup
    findRunning=NO;
    ffmpegpath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"ffmpeg" ofType:nil] retain];
    
}

- (IBAction)fileBrowse:(id)sender {
    
}

- (IBAction)fixClick:(id)sender {
    
}

- (void)media_info {
    
}

- (void)check_file {
    
}

- (void)parseOutput:(NSString *)output {
    if ([output rangeOfString:@"indexing"].location != NSNotFound) {
        //do nothing, toss the line
        
    } else if ([output rangeOfString:@"[info]"].location != NSNotFound) {
        //info to log
        [[textWindow textStorage] appendAttributedString: [[[NSAttributedString alloc]
                                                            initWithString: output] autorelease]];
        
        [self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
        
    } else if ([output rangeOfString:@"\%"].location != NSNotFound) {
        //video progress
        if ([output rangeOfString:@"remux"].location != NSNotFound) {
            [progBar setDoubleValue:100.0];
            //[completeLabel setStringValue:[NSString stringWithFormat:@"%.1f%% Completed, Pass %d/%d", [progBar doubleValue], passes_done, passes]];
            //[etaLabel setStringValue:@"Remaining: 0:00:00"];
        } else {
            NSArray *progValues = [output 
                                   captureComponentsMatchedByRegex:@".(.*)%.*, (.*) fps.*eta (.*)"];
            
            [progBar setDoubleValue:[[progValues objectAtIndex:1] doubleValue]];
            //[completeLabel setStringValue:[NSString stringWithFormat:@"%.1f%% Completed, Pass %d/%d", [progBar doubleValue], passes_done, passes]];
            //[fpsLabel setStringValue:[NSString stringWithFormat:@"FPS: %@", [progValues objectAtIndex:2]]];
            //[etaLabel setStringValue:[NSString stringWithFormat:@"Remaining: %@", [progValues objectAtIndex:3]]];
            
        }
        
    } else if ([output rangeOfString:@"encoded"].location != NSNotFound) {
        //Complete!
        
        if (passes_done == passes) {
            [closePanelButton setStringValue:@"Done!"];
            [progBar setDoubleValue:100.0];
            //[completeLabel setStringValue:[NSString stringWithFormat:@"%.1f%% Completed, Pass %d/%d", [progBar doubleValue], passes_done, passes]];
            //[etaLabel setStringValue:@"Remaining: 0:00:00"];
            [[textWindow textStorage] appendAttributedString: [[[NSAttributedString alloc]
                                                                initWithString: output] autorelease]];
            
            [self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
            [NSApp requestUserAttention:NSInformationalRequest];
        } else {
            //Do nothing
        }
    } else if ([output rangeOfString:@"[error]"].location != NSNotFound) {
        [[textWindow textStorage] appendAttributedString: [[[NSAttributedString alloc]
                                                            initWithString: output] autorelease]];
        
        [self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
        [NSApp requestUserAttention:NSInformationalRequest];
        NSAlert *encodeErrorAlert = [NSAlert alertWithMessageText:@"Encode failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Encode failed, error message was: %@", output];
        [encodeErrorAlert runModal];
    } else {
        //Otherwise, just toss it
    }
    
}


//Functions below here originally came from the Moriarty example code, some are modified
//for the needed functionality here.
- (void)appendOutput:(NSString *)output {
    [self parseOutput:output];
}

- (void)scrollToVisible:(id)ignore {
    //[textWindow scrollRangeToVisible:NSMakeRange([[textWindow string] length], 0)];
}

- (void)processStarted {
    findRunning=YES;
    //[textWindow setString:@""];
    //[closePanelButton setTitle:@"Cancel"];
}

- (void)processFinished {
    if (passes_done == passes) {
        findRunning=NO;
        //[closePanelButton setTitle:@"Done!"];  
        passes_done = 0;
    } else {
        passes_done++;
        //[self execx264];
    }
}

@end