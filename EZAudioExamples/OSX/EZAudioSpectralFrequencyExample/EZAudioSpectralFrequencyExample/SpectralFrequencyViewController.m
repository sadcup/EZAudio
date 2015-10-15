//
//  SpectralFrequencyViewController.m
//  EZAudioSpectralFrequencyExample
//
//  Created by Netiger on 10/12/15.
//  Copyright © 2015 Sadcup. All rights reserved.
//

#import "SpectralFrequencyViewController.h"

@interface SpectralFrequencyViewController ()

@end

@implementation SpectralFrequencyViewController

//------------------------------------------------------------------------------
#pragma mark - Customize the Audio Plot
//------------------------------------------------------------------------------

- (void)awakeFromNib
{
    //
    // Customizing the audio plot's look
    //
    // Background color
    self.audioPlot.backgroundColor = [NSColor colorWithCalibratedRed: 0.569 green: 0.82 blue: 0.478 alpha: 1];
    // Waveform color
    self.audioPlot.color = [NSColor colorWithCalibratedRed: 1.000 green: 1.000 blue: 1.000 alpha: 1];
    // Plot type
    self.audioPlot.plotType = EZPlotTypeBuffer;
    
    
    //
    // Customizing the spectral plot's look
    //
    // Background color
    self.spectralPlot.backgroundColor = [NSColor colorWithCalibratedRed: 0.969 green: 0.82 blue: 0.478 alpha: 1];
    // Waveform color
    self.spectralPlot.color = [NSColor colorWithCalibratedRed: 1.000 green: 1.000 blue: 1.000 alpha: 1];
    // Plot type
    self.spectralPlot.plotType = EZPlotTypeBuffer;
    
    
    //
    // Create an instance of the EZAudioFFTRolling to keep a history of the incoming audio data and calculate the FFT.
    //
    self.fft = [EZAudioFFTRolling fftWithWindowSize:256
                                         sampleRate:0
                                           delegate:self];
    
    //
    // Start the microphone
    //
    [EZMicrophone sharedMicrophone].delegate = self;
    [[EZMicrophone sharedMicrophone] startFetchingAudio];
    
    //
    // Print out the input device being used
    //
    NSLog(@"Using input device: %@", [[EZMicrophone sharedMicrophone] device]);
    
    //
    // Use the microphone as the EZOutputDataSource
    //
    [[EZMicrophone sharedMicrophone] setOutput:[EZOutput sharedOutput]];
    
    /**
     Start the output
     */
    [[EZOutput sharedOutput] startPlayback];
}

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

- (void)changePlotType:(id)sender
{
    NSInteger selectedSegment = [sender selectedSegment];
    switch(selectedSegment)
    {
        case 0:
            [self drawBufferPlot];
            break;
        case 1:
            [self drawRollingPlot];
            break;
        default:
            break;
    }
}

//------------------------------------------------------------------------------

- (void)toggleMicrophone:(id)sender
{
    switch([sender state])
    {
        case NSOffState:
            [[EZMicrophone sharedMicrophone] stopFetchingAudio];
            break;
        case NSOnState:
            [[EZMicrophone sharedMicrophone] startFetchingAudio];
            break;
        default:
            break;
    }
}

//------------------------------------------------------------------------------
#pragma mark - Action Extensions
//------------------------------------------------------------------------------

//
// Give the visualization of the current buffer (this is almost exactly the openFrameworks audio input example)
//
- (void)drawBufferPlot
{
    self.audioPlot.plotType = EZPlotTypeBuffer;
    self.audioPlot.shouldMirror = NO;
    self.audioPlot.shouldFill = NO;
    
    self.spectralPlot.plotType = EZPlotTypeBuffer;
    self.spectralPlot.shouldMirror = NO;
    self.spectralPlot.shouldFill = NO;
}

//------------------------------------------------------------------------------

//
// Give the classic mirrored, rolling waveform look
//
- (void)drawRollingPlot
{
    self.audioPlot.plotType = EZPlotTypeRolling;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;
    
    self.spectralPlot.plotType = EZPlotTypeRolling;
    self.spectralPlot.shouldFill = YES;
    self.spectralPlot.shouldMirror = YES;
}

//------------------------------------------------------------------------------
#pragma mark - EZMicrophoneDelegate
//------------------------------------------------------------------------------

- (void)microphone:(EZMicrophone *)microphone changedPlayingState:(BOOL)isPlaying
{
    NSString *title = isPlaying ? @"Microphone On" : @"Microphone Off";
    [self setTitle:title forButton:self.microphoneSwitch];
}

//------------------------------------------------------------------------------

-(void)    microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
{
    //
    // Calculate the FFT, will trigger EZAudioFFTDelegate
    //
    [self.fft computeFFTWithBuffer:buffer[0] withBufferSize:bufferSize];
    
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.audioPlot updateBuffer:buffer[0]
                          withBufferSize:bufferSize];
    });
    
}

//------------------------------------------------------------------------------
#pragma mark - Utility
//------------------------------------------------------------------------------

- (void)setTitle:(NSString *)title forButton:(NSButton *)button
{
    NSDictionary *attributes = @{ NSForegroundColorAttributeName : [NSColor whiteColor] };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                                          attributes:attributes];
    button.attributedTitle = attributedTitle;
    button.attributedAlternateTitle = attributedTitle;
}

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
#pragma mark - EZAudioFFTDelegate
//------------------------------------------------------------------------------

- (void)        fft:(EZAudioFFT *)fft
 updatedWithFFTData:(float *)fftData
         bufferSize:(vDSP_Length)bufferSize
{
    //float maxFrequency = [fft maxFrequency];
    
    __weak typeof (self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.spectralPlot updateBuffer:fftData
                          withBufferSize:bufferSize];
    });

}

//------------------------------------------------------------------------------

@end
