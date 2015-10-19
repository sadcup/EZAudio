//
//  SpectrogramViewController.m
//  EZAudioExamplesSpectrogramExample
//
//  Created by Netiger on 10/15/15.
//  Copyright © 2015 Sadcup. All rights reserved.
//

#import "SpectrogramViewController.h"

@interface SpectrogramViewController ()
@property (weak, nonatomic) IBOutlet EZAudioPlot *audioPlot;
@property (weak, nonatomic) IBOutlet EZAudioSpectralPlot *sepctrogramPlot;

@end

@implementation SpectrogramViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //
    // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
    // if you don't do this!
    //
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
    }
    [session setActive:YES error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }
    
    //
    // Customizing the audio plot's look
    //
    self.audioPlot.backgroundColor = [UIColor colorWithRed: 0.569 green: 0.82 blue: 0.478 alpha: 1];
    self.audioPlot.color = [UIColor colorWithRed: 1.000 green: 1.000 blue: 1.000 alpha: 1];
    self.audioPlot.plotType = EZPlotTypeBuffer;
    
    //self.sepctrogramPlot.backgroundColor = [UIColor colorWithRed: 0.569 green: 0.82 blue: 0.478 alpha: 1];
    //self.sepctrogramPlot.color = [UIColor colorWithRed: 1.000 green: 1.000 blue: 1.000 alpha: 1];
    //self.sepctrogramPlot.plotType = EZPlotTypeBuffer;
    
    //
    // Start the microphone
    //
    [EZMicrophone sharedMicrophone].delegate = self;
    [[EZMicrophone sharedMicrophone] startFetchingAudio];
    //self.microphoneTextLabel.text = @"Microphone On";
    
    //
    // Use the microphone as the EZOutputDataSource
    //
    [[EZMicrophone sharedMicrophone] setOutput:[EZOutput sharedOutput]];
    
    //
    // Make sure we override the output to the speaker
    //
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:NULL];
    if (error)
    {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }
    
    //
    // Start the EZOutput
    //
    [[EZOutput sharedOutput] startPlayback];
}

//------------------------------------------------------------------------------
#pragma mark - EZMicrophoneDelegate
//------------------------------------------------------------------------------

- (void)    microphone:(EZMicrophone *)microphone
      hasAudioReceived:(float **)buffer
        withBufferSize:(UInt32)bufferSize
  withNumberOfChannels:(UInt32)numberOfChannels
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.sepctrogramPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

@end