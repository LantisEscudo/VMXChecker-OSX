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
int framesComplete;
int inputWidth;
int inputHeight;
NSString *videoFormat;
NSString *videoFormatVersion;
NSString *videoFormatProfile;
NSString *videoDAR;
NSString *videoScanType;
NSString *videofps;
NSString *audioFormat;
NSString *audioFormatVersion;
NSString *audioFormatProfile;
int audioSamplingRate;
bool correctVideoFormat;
bool correctAudioFormat;


@synthesize window;
@synthesize ffmpegpath;

- (void) awakeFromNib {
    //Code for startup
    findRunning=NO;
    ffmpegpath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"ffmpeg" ofType:nil] retain];
    inputfilename = @"";
    frames = 0;
    framesComplete = 0;
    inputWidth = 0;
    inputHeight = 0;
    videoFormat = @"";
    videoFormatVersion = @"";
    videoFormatProfile = @"";
    videoDAR = @"";
    videoScanType = @"";
    videofps = @"";
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

- (IBAction)cancelClick:(id)sender {
    if ([[closePanelButton title] isEqualToString:@"Cancel"]) {
        NSAlert *confirmCancel = [NSAlert alertWithMessageText:@"Confirm Cancel Encode" 
                                                 defaultButton:@"No"
                                               alternateButton:@"Yes" 
                                                   otherButton:nil 
                                     informativeTextWithFormat:@"Are you sure you want to cancel encoding?"];
        if ([confirmCancel runModal] == NSAlertAlternateReturn) {
            [self encode];
            [closePanelButton setTitle:@"Close"];
        }
        //Don't do anything if they click "No"
        
    } else {
        [encodePanel setIsVisible:NO];
        [closePanelButton setTitle:@"Cancel"];
        [window setIsVisible:YES];
    }

}

- (void)media_info {
    NSTask *MITask = [[NSTask alloc] init];
    NSPipe *MIPipe = [[NSPipe alloc] init];
    NSFileHandle *MIReadHandle = [MIPipe fileHandleForReading];
    
    [MITask setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"mediainfo" ofType:nil]];
    [MITask setArguments:[NSArray arrayWithObjects:@"--Output=XML", @"--Full", inputfilename, nil]];
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
    
    tempnodes = [vt nodesForXPath:@"./Display_aspect_ratio" error:nil];
    videoDAR = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";    
    
    tempnodes = [vt nodesForXPath:@"./Scan_type" error:nil];
    videoScanType = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";    
    
    tempnodes = [vt nodesForXPath:@"./Frame_rate" error:nil];
    videofps = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    NSXMLElement *at = [atracks objectAtIndex:0];
    tempnodes = [at nodesForXPath:@"./Format" error:nil];
    audioFormat = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Format_profile" error:nil];
    audioFormatProfile = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Format_version" error:nil];
    audioFormatVersion = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Sampling_rate" error:nil];
    audioSamplingRate = ([tempnodes count] > 0) ? [[[tempnodes objectAtIndex:0] stringValue] intValue] : 0;

/*  
    NSLog([NSString stringWithFormat:@"Video Format: %@", videoFormat]);
    NSLog([NSString stringWithFormat:@"Video Format Profile: %@", videoFormatProfile]);
    NSLog([NSString stringWithFormat:@"Video Format Version: %@", videoFormatVersion]);
    NSLog([NSString stringWithFormat:@"Audio Format: %@", audioFormat]);
    NSLog([NSString stringWithFormat:@"Audio Format Profile: %@", audioFormatProfile]);
    NSLog([NSString stringWithFormat:@"Audio Format Version: %@", audioFormatVersion]);
    NSLog([NSString stringWithFormat:@"Audio Sampling Rate: %@", audioSamplingRate]);
    NSLog([[tempnodes objectAtIndex:0] stringValue]);
*/
}

- (void)check_file {
    correctVideoFormat = true;
    correctAudioFormat = true;
    
    if ([inputfilename isNotEqualTo:@""] && [videoFormat isEqualToString:@"MPEG Video"] && [videoFormatVersion isEqualToString:@"Version 2"] && [videoFormatProfile isEqualToString:@"Main@Main"] && [videoDAR isEqualToString:@"4:3"] && [videoScanType isEqualToString:@"Interlaced"] && [videofps isEqualToString:@"29.970"] && inputWidth == 720 && inputHeight == 480) {
        
        [videoPropertiesLabel setStringValue:@"Correct Video Format"];
        [videoPropertiesLabel setTextColor:[NSColor greenColor]];
    } else {
        NSMutableString *errorstring = [NSMutableString stringWithString:@""];
        if (![videoFormat isEqualToString:@"MPEG Video"] || ![videoFormatVersion isEqualToString:@"Version 2"]) {
            [errorstring appendString:@"Not MPEG-2 Video\n"];
            
        } else if (![videoFormatProfile isEqualToString:@"Main@Main"]) {
            [errorstring appendString:@"Incorrect MPEG Profile\n"];
        }

        if (![videoDAR isEqualToString:@"4:3"]) {
            [errorstring appendString:@"Incorrect Aspect Ratio\n"];
        }
        
        if (![videoScanType isEqualToString:@"Interlaced"]) {
            [errorstring appendString:@"Incorrect Scan Mode\n"];
        }
        
        if (![videofps isEqualToString:@"29.970"]) {
            [errorstring appendString:@"Incorrect Frame Rate\n"];
        }
        
        if ((inputHeight != 480) || (inputWidth != 720)) {
            [errorstring appendString:@"Incorrect Resolution"];
        }
        
        [videoPropertiesLabel setStringValue:errorstring];
        [videoPropertiesLabel setTextColor:[NSColor redColor]];
        correctVideoFormat = false;

    }
    
    if ([audioFormat isEqualToString:@"MPEG Audio"] && [audioFormatVersion isEqualToString:@"Version 1"] && [audioFormatProfile isEqualToString:@"Layer 2"] && audioSamplingRate == 48000) {
        
        [audioPropertiesLabel setStringValue:@"Correct audio format"];
        [audioPropertiesLabel setTextColor:[NSColor greenColor]];
    } else {
        NSMutableString *errorstring = [NSMutableString stringWithString:@""];
        
        if (![audioFormat isEqualToString:@"MPEG Audio"]) {
            if ([audioFormat isEqualToString:@"AC-3"]) {
                [errorstring appendString:@"Dolby Digital Audio\n"];
            } else {
                [errorstring appendString:@"Incorrect Audio Format\n"];
            }
        } else if (![audioFormatProfile isEqualToString:@"Layer 2"] || ![audioFormatVersion isEqualToString:@"Version 1"]) {
            [errorstring appendString:@"Incorrect MPEG Audio Profile\n"];
        }
        
        if (audioSamplingRate != 48000) {
            [errorstring appendString:@"Incorrect sampling rate"];
        }
        
        
        [audioPropertiesLabel setStringValue:errorstring];
        [audioPropertiesLabel setTextColor:[NSColor redColor]];
        correctAudioFormat = false;
    }

    if (correctAudioFormat && correctVideoFormat) {
        [messageLabel setStringValue:@"There are no problems with this file."];
        [messageLabel setTextColor:[NSColor greenColor]];
        [fixButton setEnabled:false];
    } else {
        [messageLabel setStringValue:@"There is a problem with this file.  Click the Fix button to correct the problem."];
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
    videoDAR = @"";
    videoScanType = @"";
    videofps = @"";
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

- (void)encode {
    if (findRunning) {
        [encodeTask stopProcess];
        [encodeTask release];
        encodeTask = nil;
        return;
    } else {
        NSArray *args = [self buildCommandLine];
        
        encodeTask = [[TaskWrapper alloc] initWithController:self arguments:args];
        [encodeTask startProcess];
    }
}

- (NSArray*)buildCommandLine {
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:12];
    
    [args addObject:ffmpegpath];
    [args addObject:@"-i"];
    [args addObject:[inputFileBox stringValue]];
    [args addObject:@"-target"];
    [args addObject:@"ntsc-dvd"];
    
    if (correctVideoFormat) {
        [args addObject:@"-vcodec"];
        [args addObject:@"copy"];
    }
    
    if (correctAudioFormat) {
        [args addObject:@"-acodec"];
        [args addObject:@"copy"];
    } else {
        [args addObject:@"-acodec"];
        [args addObject:@"mp2"];
        [args addObject:@"-b:a"];
        [args addObject:@"192k"];
    }
    
    [args addObject:[NSString stringWithFormat:@"%@-VMX.mpg", [inputfilename stringByDeletingPathExtension]]];
    
    
    return args;
    
}

- (void)parseOutput:(NSString *)output {
    
    if ([output rangeOfString:@"frame="].location != NSNotFound) {
        //Video progress
        NSArray *progValues = [output captureComponentsMatchedByRegex:@"frame=.*?(\\d+) fps=.*?(\\d+\\.?\\d*)"];
        
        [progBar setDoubleValue:[[progValues objectAtIndex:0] doubleValue]];
        framesComplete = [[progValues objectAtIndex:0] intValue];
        [progressLabel setStringValue:[NSString stringWithFormat:@"Complete: %.1f%%", framesComplete/frames]];
        [fpsLabel setStringValue:[NSString stringWithFormat:@"FPS: %@", [progValues objectAtIndex:1]]];
        [framesLabel setStringValue:[NSString stringWithFormat:@"Progress: %d/%d", framesComplete, frames]];
    
    } else if ([output rangeOfString:@"video:"].location != NSNotFound) {
        //Encoding Complete!
        [closePanelButton setStringValue:@"Done!"];
        [progBar setDoubleValue:[progBar maxValue]];
        [[textWindow textStorage] appendAttributedString: [[[NSAttributedString alloc]
                                                            initWithString: output] autorelease]];
            
        [self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
        [NSApp requestUserAttention:NSInformationalRequest];
        
    } else if ([output rangeOfString:@"Error while"].location != NSNotFound) {
        [[textWindow textStorage] appendAttributedString: [[[NSAttributedString alloc]
                                                            initWithString: output] autorelease]];
        
        [self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
        [NSApp requestUserAttention:NSInformationalRequest];
        NSAlert *encodeErrorAlert = [NSAlert alertWithMessageText:@"Encode failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Encode failed, error message was: %@", output];
        [encodeErrorAlert runModal];
        
    } else {
        //Output to Log
        [[textWindow textStorage] appendAttributedString: [[[NSAttributedString alloc]
                                                            initWithString: output] autorelease]];
        
        [self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
    }
    
}


//Functions below here originally came from the Moriarty example code, some are modified
//for the needed functionality here.
- (void)appendOutput:(NSString *)output {
    [self parseOutput:output];
}

- (void)scrollToVisible:(id)ignore {
    [textWindow scrollRangeToVisible:NSMakeRange([[textWindow string] length], 0)];
}

- (void)processStarted {
    findRunning=YES;
    [textWindow setString:@""];
    [closePanelButton setTitle:@"Cancel"];
}

- (void)processFinished {
    findRunning=NO;
    [closePanelButton setTitle:@"Done!"];
}

@end