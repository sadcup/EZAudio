//
//  SpectralFrequencyViewController.h
//  EZAudioSpectralFrequencyExample
//
//  Created by Netiger on 10/12/15.
//  Copyright © 2015 Sadcup. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 Import EZAudio
 */
#import "EZAudio.h"

@interface SpectralFrequencyViewController : NSViewController <EZMicrophoneDelegate, EZAudioFFTDelegate>

//------------------------------------------------------------------------------
#pragma mark - Components
//------------------------------------------------------------------------------

/**
 The OpenGL based audio plot
 */
@property (nonatomic, weak) IBOutlet EZAudioPlotGL *audioPlot;

/**
 The Spectral Frequency plot
 */
@property (nonatomic, weak) IBOutlet EZAudioSpectralPlot *spectralPlot;


//------------------------------------------------------------------------------

/**
 The label used to display the microphone state
 */
@property (nonatomic, weak) IBOutlet NSButton *microphoneSwitch;

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

/**
 Switches the plot drawing type between a buffer plot (visualizes the current stream of audio data from the update function) or a rolling plot (visualizes the audio data over time, this is the classic waveform look)
 */
-(IBAction)changePlotType:(id)sender;

//------------------------------------------------------------------------------

/**
 Toggles the microphone on and off. When the microphone is on it will send its delegate (aka this view controller) the audio data in various ways (check out the EZMicrophoneDelegate documentation for more details);
 */
-(IBAction)toggleMicrophone:(id)sender;

//------------------------------------------------------------------------------

/**
 Used to calculate a rolling FFT of the incoming audio data.
 */
@property (nonatomic, strong) EZAudioFFTRolling *fft;

@end
 