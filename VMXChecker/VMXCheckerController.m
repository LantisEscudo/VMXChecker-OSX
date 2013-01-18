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
NSString *inputfilename;
int frames;
int inputWidth;
int inputHeight;
NSString *videoFormat;
NSString *videoFormatVersion;
NSString *videoFormatProfile;
NSString *audioFormat;
NSString *audioFormatVersion;
NSString *audioFormatProfile;
NSString *audioSamplingRate;
BOOL correctVideoFormat;
bool correctAudioFormat;

NSFont *grayFont;


@synthesize window;
@synthesize ffmpegpath;

- (void) awakeFromNib {
    //Code for startup
    findRunning=NO;
    ffmpegpath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"ffmpeg" ofType:nil] retain];
    inputfilename = @"";
    frames = 0;
    inputWidth = 0;
    inputHeight = 0;
    videoFormat = @"";
    videoFormatVersion = @"";
    videoFormatProfile = @"";
    audioFormat = @"";
    audioFormatVersion = @"";
    audioFormatProfile = @"";
    audioSamplingRate = 0;
    correctVideoFormat = true;
    correctAudioFormat = true;
    
    
    
}

- (IBAction)fileBrowse:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    NSArray *fileTypes = [[NSArray alloc] initWithObjects:@"mpg", @"MPG", @"mpeg", @"MPEG", nil];
    
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setAllowedFileTypes:fileTypes];
    
    if ( [openDlg runModalForTypes:fileTypes] == NSOKButton )
    {
        NSURL* fileName = [openDlg URL];
        
        // Do something with the filename.
        inputfilename = [fileName path];
        [inputFileBox setStringValue:inputfilename];
        [self media_info];
        if ([inputfilename isNotEqualTo:@""]) {
            [self check_file];            
        }
    }
}

- (IBAction)fixClick:(id)sender {
    
}

- (void)media_info {
    NSTask *MITask = [[NSTask alloc] init];
    NSPipe *MIPipe = [[NSPipe alloc] init];
    NSFileHandle *MIReadHandle = [MIPipe fileHandleForReading];
    
    [MITask setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"mediainfo" ofType:nil]];
    [MITask setArguments:[NSArray arrayWithObjects:@"--Output=XML", inputfilename, nil]];
    [MITask setStandardError:MIPipe];
    [MITask setStandardOutput:MIPipe];
    
    [MITask launch];
    
    NSData *MIOutput = [MIReadHandle readDataToEndOfFile];
    [MITask waitUntilExit];
    
    NSError *MIErr;
    
    NSXMLDocument *MIParsedOutput = [[NSXMLDocument alloc] initWithData:MIOutput options:NSXMLDocumentTidyXML error:&MIErr];
    NSArray *vtracks = [MIParsedOutput nodesForXPath:@"./Mediainfo/File/track[@type='Video']" error:nil];
    NSArray *atracks = [MIParsedOutput nodesForXPath:@"./Mediainfo/File/track[@type='Audio']" error:nil];
    
    if ([vtracks count] < 1) {
        //Not video file, alert and bail
        NSAlert *noVidAlert = [NSAlert alertWithMessageText:@"No video stream found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"No video stream was found in the file."];
        [self reset_fields];
        [noVidAlert runModal];
        return;
    }
        
    if ([atracks count] < 1) {
        //No audio tracks, alert and bail
        NSAlert *noAudAlert = [NSAlert alertWithMessageText:@"No audio stream found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"No audio stream was found in the file."];
        [self reset_fields];
        [noAudAlert runModal];
        return;
    }
    
    NSXMLElement *vt = [vtracks objectAtIndex:0];
    NSString *heightString = [[[vt nodesForXPath:@"./Height" error:nil] objectAtIndex:0] stringValue];
    heightString = [heightString stringByReplacingOccurrencesOfString:@" pixels" 
                                                           withString:@""];
    inputHeight = [heightString intValue];
    NSString *widthString = [[[vt nodesForXPath:@"./Width" error:nil] objectAtIndex:0] stringValue];
    widthString = [widthString stringByReplacingOccurrencesOfString:@" pixels" 
                                                         withString:@""];
    inputWidth = [widthString intValue];
    
    NSArray *tempnodes = [vt nodesForXPath:@"./Format" error:nil];

    videoFormat = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [vt nodesForXPath:@"./Format_profile" error:nil];
    videoFormatProfile = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [vt nodesForXPath:@"./Format_version" error:nil];
    videoFormatVersion = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    NSXMLElement *at = [atracks objectAtIndex:0];
    tempnodes = [at nodesForXPath:@"./Format" error:nil];
    audioFormat = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Format_profile" error:nil];
    audioFormatProfile = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Format_version" error:nil];
    audioFormatVersion = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Sampling_rate" error:nil];
    audioSamplingRate = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
/*    NSLog([NSString stringWithFormat:@"Video Format: %@", videoFormat]);
    NSLog([NSString stringWithFormat:@"Video Format Profile: %@", videoFormatProfile]);
    NSLog([NSString stringWithFormat:@"Video Format Version: %@", videoFormatVersion]);
    NSLog([NSString stringWithFormat:@"Audio Format: %@", audioFormat]);
    NSLog([NSString stringWithFormat:@"Audio Format Profile: %@", audioFormatProfile]);
    NSLog([NSString stringWithFormat:@"Audio Format Version: %@", audioFormatVersion]);
    NSLog([NSString stringWithFormat:@"Audio Sampling Rate: %@", audioSamplingRate]);*/
}

- (void)check_file {
    correctVideoFormat = true;
    correctAudioFormat = true;
    [videoPropertiesLabel setStringValue:[NSString stringWithFormat:@"%@\n%@\n%@\n%dx%d", videoFormat, videoFormatVersion, videoFormatProfile, inputWidth, inputHeight]];
    
    if ([inputfilename isNotEqualTo:@""] && [videoFormat isEqualToString:@"MPEG Video"] && [videoFormatVersion isEqualToString:@"Version 2"] && [videoFormatProfile isEqualToString:@"Main@Main"] && inputWidth == 720 && inputHeight == 480) {
        
        [videoPropertiesLabel setTextColor:[NSColor greenColor]];
    } else {
        [videoPropertiesLabel setTextColor:[NSColor redColor]];
        correctVideoFormat = false;

    }
    
    [audioPropertiesLabel setStringValue:[NSString stringWithFormat:@"%@\n%@\n%@\n%@", audioFormat, audioFormatVersion, audioFormatProfile, audioSamplingRate]];

    if ([audioFormat isEqualToString:@"MPEG Audio"] && [audioFormatVersion isEqualToString:@"Version 1"] && [audioFormatProfile isEqualToString:@"Layer 2"] && [audioSamplingRate isEqualToString:@"48.0 KHz"]) {
        
        [audioPropertiesLabel setTextColor:[NSColor greenColor]];
    } else {
        [audioPropertiesLabel setTextColor:[NSColor redColor]];
        correctAudioFormat = false;
    }

    if (correctAudioFormat && correctVideoFormat) {
        [messageLabel setStringValue:@"This file is the correct format to upload."];
        [messageLabel setTextColor:[NSColor greenColor]];
        [fixButton setEnabled:false];
    } else {
        [messageLabel setStringValue:@"There is a problem with this file.  Click the Fix button to repair the issue."];
        [messageLabel setTextColor:[NSColor redColor]];
        [fixButton setEnabled:true];
    }


}

- (void)reset_fields {
    inputfilename = @"";
    frames = 0;
    inputWidth = 0;
    inputHeight = 0;
    videoFormat = @"";
    videoFormatVersion = @"";
    videoFormatProfile = @"";
    audioFormat = @"";
    audioFormatVersion = @"";
    audioFormatProfile = @"";
    audioSamplingRate = 0;
    correctAudioFormat = true;
    correctVideoFormat = true;

    [inputFileBox setStringValue:inputfilename];
    [fixButton setEnabled:false];
    [videoPropertiesLabel setTextColor:[NSColor grayColor]];
    [videoPropertiesLabel setStringValue:@"No Video Loaded"];
    [audioPropertiesLabel setTextColor:[NSColor grayColor]];
    [audioPropertiesLabel setStringValue:@"No Audio Loaded"];
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