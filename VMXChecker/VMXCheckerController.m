//
//  VMXCheckerController.m
//  VMXChecker
//
/*
 This software is licensed under the MIT License:
 
 Copyright (C) 2013 Michael Montanye
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "VMXCheckerController.h"

@implementation VMXCheckerController

TaskWrapper* encodeTask;
int passes;
int passes_done;
NSString *inputfilename;
NSString *outputfilename;
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
    outputfilename = @"";
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
    
    NSArray *fileTypes = [[NSArray alloc] initWithObjects:@"mpg", @"MPG", @"mpeg", @"MPEG", @"mp4", @"MP4", nil];
    
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
    
    [fileTypes release];    
}

- (IBAction)fixClick:(id)sender {
        
    //Test for input exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:[inputFileBox stringValue]]) {
        NSAlert *notFoundSourceAlert = [NSAlert 
                                        alertWithMessageText:@"Source File Not Found" 
                                        defaultButton:@"OK" 
                                        alternateButton:nil 
                                        otherButton:nil 
                                        informativeTextWithFormat:@"The source file could not be found."];
        [notFoundSourceAlert runModal];
        return;
    }
        
    //Test for destination exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@-VMX.mpg", [inputfilename stringByDeletingPathExtension]]]) {
        NSAlert *confirmOverwrite = [NSAlert alertWithMessageText:@"Confirm Overwrite" 
                                                    defaultButton:@"No"
                                                  alternateButton:@"Yes" 
                                                      otherButton:nil 
                                        informativeTextWithFormat:@"Destination file exists. Do you want to overwrite?"];
        if ([confirmOverwrite runModal] == NSAlertDefaultReturn) {
            return;
        }
    }
    
    [window setIsVisible:NO];
    [encodePanel setIsVisible:YES];
    [self encode];

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
        
        if ([[closePanelButton title] isEqualToString:@"Done!"]) {
            [inputFileBox setStringValue:outputfilename];
            inputfilename = outputfilename;
            [self media_info];
            [self check_file];
        }
        
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
        [MIPipe release];
        [MITask release];
        [MIParsedOutput release];
        return;
    }
        
    if ([atracks count] < 1) {
        //No audio tracks, alert and bail
        NSAlert *noAudAlert = [NSAlert alertWithMessageText:@"No audio stream found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"No audio stream was found in the file."];
        [self reset_fields];
        [noAudAlert runModal];
        [MIPipe release];
        [MITask release];
        [MIParsedOutput release];
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
    [videoScanType retain];
    
    tempnodes = [vt nodesForXPath:@"./Frame_rate" error:nil];
    videofps = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [vt nodesForXPath:@"./Frame_count" error:nil];
    frames = ([tempnodes count] > 0) ? [[[tempnodes objectAtIndex:0] stringValue] intValue] : 0;
    
    NSXMLElement *at = [atracks objectAtIndex:0];
    tempnodes = [at nodesForXPath:@"./Format" error:nil];
    audioFormat = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Format_profile" error:nil];
    audioFormatProfile = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Format_version" error:nil];
    audioFormatVersion = ([tempnodes count] > 0) ? [[tempnodes objectAtIndex:0] stringValue] : @"";
    
    tempnodes = [at nodesForXPath:@"./Sampling_rate" error:nil];
    audioSamplingRate = ([tempnodes count] > 0) ? [[[tempnodes objectAtIndex:0] stringValue] intValue] : 0;

    [MIPipe release];
    [MITask release];
    [MIParsedOutput release];
}

- (void)check_file {
    correctVideoFormat = true;
    correctAudioFormat = true;
    
    if ([inputfilename isNotEqualTo:@""] && [videoFormat isEqualToString:@"MPEG Video"] && [videoFormatVersion isEqualToString:@"Version 2"] && [videoFormatProfile isEqualToString:@"Main@Main"] && ([videoDAR isEqualToString:@"4:3"] || [videoDAR isEqualToString:@"1.333"]) && [videoScanType isEqualToString:@"Interlaced"] && [videofps isEqualToString:@"29.970"] && inputWidth == 720 && inputHeight == 480) {
        
        [videoPropertiesLabel setStringValue:@"Correct Video Format"];
        [videoPropertiesLabel setTextColor:[NSColor greenColor]];
    } else {
        NSMutableString *errorstring = [NSMutableString stringWithString:@""];
        if (![videoFormat isEqualToString:@"MPEG Video"] || ![videoFormatVersion isEqualToString:@"Version 2"]) {
            [errorstring appendString:@"Not MPEG-2 Video\n"];
            
        } else if (![videoFormatProfile isEqualToString:@"Main@Main"]) {
            [errorstring appendString:@"Incorrect MPEG Profile\n"];
        }

        if (![videoDAR isEqualToString:@"4:3"] && ![videoDAR isEqualToString:@"1.333"]) {
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
        NSArray *args = [self newCommandLine];
        
        encodeTask = [[TaskWrapper alloc] initWithController:self arguments:args];
        [encodeTask startProcess];
        [args autorelease];
    }
}

- (NSArray*)newCommandLine {
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:12];
    
    [args addObject:ffmpegpath];
    [args addObject:@"-i"];
    [args addObject:[inputFileBox stringValue]];
    [args addObject:@"-y"];
    [args addObject:@"-target"];
    [args addObject:@"ntsc-dvd"];
    
    if (correctVideoFormat) {
        [args addObject:@"-vcodec"];
        [args addObject:@"copy"];
    } else {
        //Correct interlacing
        if ([videoScanType isEqualToString:@"Progressive"]) {
            [args addObject:@"-flags"];
            [args addObject:@"+ildct+ilme"];
            [args addObject:@"-top"];
            [args addObject:@"0"];
        }
        //Correct 16:9 aspect ratios
        if ([videoDAR isEqualToString:@"16:9"]) {
            [args addObject:@"-vf"];
            [args addObject:@"scale=720:360,pad=720:480:0:60"];
        }
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
    
    outputfilename = [NSString stringWithFormat:@"%@-VMX.mpg", [inputfilename stringByDeletingPathExtension]];
    [args addObject:outputfilename];
    
    //NSLog([NSString stringWithFormat:@"%@", [args componentsJoinedByString:@" "]]);
    
    return args;
    
}

- (void)parseOutput:(NSString *)output {
    
    if ([output rangeOfString:@"frame="].location != NSNotFound) {
        //Video progress
        NSArray *progValues = [output captureComponentsMatchedByRegex:@"frame=.*?(\\d+) fps=.*?(\\d+\\.?\\d*)"];
        
        
        
        framesComplete = [[progValues objectAtIndex:1] intValue];
        if (framesComplete > frames)
            framesComplete = frames;
        
        double percent = ((double)framesComplete/(double)frames)*100;
        
        //NSLog([NSString stringWithFormat:@"%d, %d, %f", framesComplete, frames, percent]);
        
        [progressLabel setStringValue:[NSString stringWithFormat:@"Complete: %.1f%%", percent]];
        [progBar setDoubleValue:percent];
        [fpsLabel setStringValue:[NSString stringWithFormat:@"FPS: %@", [progValues objectAtIndex:2]]];
        [framesLabel setStringValue:[NSString stringWithFormat:@"Progress: %d/%d frames", framesComplete, frames]];
    
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
    } else if ([output rangeOfString:@"Press [q]"].location != NSNotFound) {
        
        //Remove "Press [q] to stop..." part, output the rest
        NSString *substr = [output substringToIndex:[output rangeOfString:@"Press [q]"].location - 1];
        [[textWindow textStorage] appendAttributedString: [[[NSAttributedString alloc]
                                                            initWithString: substr] autorelease]];
        [self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
        
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