//
//  EZAudioSpectralPlot.h
//  EZAudio
//
//  Created by Syed Haris Ali on 9/2/13.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <QuartzCore/QuartzCore.h>
#import "EZPlot.h"
#import "EZAudioSTFT.h"

@class EZAudio;

//------------------------------------------------------------------------------
#pragma mark - Constants
//------------------------------------------------------------------------------

/**
 The default value used for the default rolling history buffer length of any EZAudioSpectralPlot.
 */
FOUNDATION_EXPORT UInt32 const EZAudioSpectralPlotDefaultHistoryBufferLength;

/**
 The default value used for the maximum rolling history buffer length of any EZAudioSpectralPlot.
 */
FOUNDATION_EXPORT UInt32 const EZAudioSpectralPlotDefaultMaxHistoryBufferLength;

//------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlotWaveformLayer
//------------------------------------------------------------------------------

/**
 The EZAudioSpectralPlotWaveformLayer is a lightweight subclass of the CAShapeLayer that allows implicit animations on the `path` key.
 */
//@interface EZAudioSpectralPlotWaveformLayer : CAShapeLayer
@interface EZAudioSpectralPlotWaveformLayer : CALayer
@property (nonatomic, assign) CGContextRef imagContext;
@property (nonatomic, assign) UInt32 * data;
@property (nonatomic, assign) UInt32 rollingBufferLength;
@property (nonatomic, assign) UInt32  width;
@property (nonatomic, assign) UInt32  height;

- (instancetype)initWithWidth:(UInt32)width height:(UInt32)height;

@end

//------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlot
//------------------------------------------------------------------------------

@interface EZAudioSpectralPlot : EZPlot <EZAudioSTFTDelegate>

/**
 A BOOL that allows optimizing the audio plot's drawing for real-time displays. Since the update function may be updating the plot's data very quickly (over 60 frames per second) this property will throttle the drawing calls to be 60 frames per second (or whatever the screen rate is). Specifically, it disables implicit path change animations on the `waveformLayer` and sets up a display link to render 60 fps (audio updating the plot at 44.1 kHz causes it to re-render 86 fps - far greater than what is needed for a visual display).
 */
@property (nonatomic, assign) BOOL shouldOptimizeForRealtimePlot;

//------------------------------------------------------------------------------

/**
 An EZAudioSpectralPlotWaveformLayer that is used to render the actual waveform. By switching the drawing code to Core Animation layers in version 0.2.0 most work, specifically the compositing step, is now done on the GPU. Hence, multiple EZAudioSpectralPlot instances can be used simultaneously with very low CPU overhead so these are now practical for table and collection views.
 */
@property (nonatomic, strong) EZAudioSpectralPlotWaveformLayer *spectrogramLayer;

/**
 Provides the default length of the rolling history buffer when the plot is initialized. Default is `EZAudioSpectralPlotDefaultHistoryBufferLength` constant.
 @return An int describing the initial length of the rolling history buffer.
 */
- (int)defaultRollingHistoryLength;

//------------------------------------------------------------------------------

/**
 Called after the view has been created. Subclasses should use to add any additional methods needed instead of overriding the init methods.
 */
- (void)setupPlot;

//------------------------------------------------------------------------------

/**
 Provides the default number of points that will be used to initialize the graph's points data structure that holds. Essentially the plot starts off as a flat line of this many points. Default is 100.
 @return An int describing the initial number of points the plot should have when flat lined.
 */
- (int)initialPointCount;

//------------------------------------------------------------------------------

/**
 Provides the default maximum rolling history length - that is, the maximum amount of points the `setRollingHistoryLength:` method may be set to. If a length higher than this is set then the plot will likely crash because the appropriate resources are only allocated once during the plot's initialization step. Defualt is `EZAudioSpectralPlotDefaultMaxHistoryBufferLength` constant.
 @return An int describing the maximum length of the absolute rolling history buffer.
 */
- (int)maximumRollingHistoryLength;

//------------------------------------------------------------------------------

/**
 Method to cause the waveform layer's path to get recreated and redrawn on screen using the last buffer of data provided. This is the equivalent to the drawRect: method used to normally subclass a view's drawing. This normally don't need to be overrode though - a better approach would be to override the `createPathWithPoints:pointCount:inRect:` method.
 */
- (void)redraw;

//------------------------------------------------------------------------------

/**
 Main method used to copy the sample data from the source buffer and update the 
 plot. Subclasses can overwrite this method for custom behavior.
 @param data   A float array of the sample data. Subclasses should copy this data to a separate array to avoid threading issues.
 @param length The length of the float array as an int.
 */
-(void)setSampleData:(float *)data length:(int)length;

//------------------------------------------------------------------------------

@property (nonatomic, strong) EZAudioSTFT * stft;


@end