//
//  EZAudioSTFT.h
//  EZAudioExamplesSpectrogramExample
//
//  Created by Netiger on 10/19/15.
//  Copyright © 2015 Sadcup. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "EZAudioFFT.h"

@class EZAudioSTFT;
/**
 The EZAudioSTFTDelegate provides event callbacks for the EZAudioSTFT whenvever the STFT is computed.
 */
@protocol EZAudioSTFTDelegate <NSObject>

@optional

///----------------------------------------------------------------------------
/// @name Getting STFT Output Data
///----------------------------------------------------------------------------

/**
 Triggered when the EZAudioSTFT computes an STFT from a buffer of input data. Provides an matrix of float data representing the computed STFT.
 @param stft       The EZAudioSTFT instance that triggered the event.
 @param stftData   A float pointer representing the float matrix of stft data.
 @param bufferSize A vDSP_Length (unsigned long) representing the length of the float matrix.
 */
- (void)        stft:(EZAudioSTFT *)stft
 updatedWithSTFTData:(float *)stftData
          bufferSize:(vDSP_Length)bufferSize;

@end

//------------------------------------------------------------------------------
#pragma mark - EZAudioSTFT
//------------------------------------------------------------------------------

/**
 The EZAudioSTFT provides a base class to quickly calculate the STFT of incoming audio data using the Accelerate framework. In addition, the EZAudioSTFT contains an EZAudioSTFTDelegate to receive an event anytime an STFT is computed.
 */

@interface EZAudioSTFT : NSObject <EZAudioFFTDelegate>

- (instancetype)initWithBufferSize:(vDSP_Length)bufferSize fftSize:(UInt32)fftSize sampleRate:(float)sampleRate delegate:(id<EZAudioSTFTDelegate>)delegate;

/**
 *  STFT Calculation
 *
 *  @param buffer     The input data
 *  @param bufferSize The length of input data
 *
 *  @return The STFT result, a float matrix
 */
- (float *)computeSTFTWithBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize;

/**
 *  A build-in FFT which is used to calculate STFT
 */
@property (nonatomic, strong) EZAudioFFT * fft;

/**
 *  STFT delegate
 */
@property (weak, nonatomic) id<EZAudioSTFTDelegate> delegate;


/**
 *  STFT windows
 */
@property (nonatomic, assign) float * windows;

/**
 *  STFT windows length
 */
@property (nonatomic, assign) UInt32 windowsLength;

/**
 *  STFT local buffer stores the data of the last packet with the lengthof windowsLength
 *  (A windowsLength delay exists in STFT, because there is not enough data to calculate the last windowsLength data's STFT)
 */
@property (nonatomic, assign) float * localBuffer;

/**
 *  STFT results
 */
@property (nonatomic, assign) float *stftData;

/**
 *  The length of the current input data
 */
@property (nonatomic, assign) vDSP_Length bufferSize;

/**
 *  The fft size
 */
@property (nonatomic, assign) UInt32 fftSize;

/**
 *  The fft workspace
 */
@property (nonatomic, assign) float * fftSink;

@end
