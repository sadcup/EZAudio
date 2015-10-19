//
//  EZAudioSTFT.m
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

#import "EZAudioSTFT.h"

@implementation EZAudioSTFT

- (instancetype)initWithBufferSize:(vDSP_Length)bufferSize fftSize:(UInt32)fftSize sampleRate:(float)sampleRate delegate:(id<EZAudioSTFTDelegate>)delegate {
    self = [super init];
    if (self) {
        
        self.fft = [EZAudioFFT fftWithMaximumBufferSize:2048 sampleRate:0.0];
        self.bufferSize = bufferSize;
        self.stftData = calloc(fftSize/2 * bufferSize, sizeof(float));
        
        self.fftSize = fftSize;
        self.fftSink = calloc(fftSize, sizeof(float));
    }
    return self;
}

- (void)dealloc {
    free(self.stftData);
    free(self.fftSink);
}

- (float *)computeSTFTWithBuffer:(float *)buffer
                  withBufferSize:(UInt32)bufferSize
{
    //NSLog(@"%u", (unsigned int)bufferSize);
    
    if (buffer == NULL)
    {
        return NULL;
    }
    
    int windowLength = 64;
    
    float maxValue = CGFLOAT_MIN;
    
    for (int i = 0; i < bufferSize; i++) {
        
        for (int j = 0; j < windowLength; j++) {
            if (i+j < bufferSize) {
                self.fftSink[j] = buffer[i+j];
            } else {
                self.fftSink[j] = 0.0;
            }
        }
        for (int j=windowLength; j<self.fftSize; j++) {
            self.fftSink[j] = 0.0;
        }
        
        float * fftData = [self.fft computeFFTWithBuffer:self.fftSink withBufferSize:self.fftSize];
        
        for (int k=0; k<self.fftSize/2; k++) {
            float thisValue = fftData[k];//fabs(fftData[k]);
            if ( thisValue > maxValue) {
                maxValue = thisValue;
            }
            
            self.stftData[i * self.fftSize/2 + k] = thisValue;
        }
        
    }
    
    for (int i=0; i<bufferSize; i++) {
        for (int j=0; j<self.fftSize/2; j++) {
            self.stftData[i*self.fftSize/2 + j] /= maxValue;
        }
    }
    
    
    //
    // Notify delegate
    //
    if ([self.delegate respondsToSelector:@selector(stft:updatedWithSTFTData:bufferSize:)])
    {
        [self.delegate stft:self updatedWithSTFTData:self.stftData bufferSize:self.fftSize/2*self.bufferSize];
    }
    
    return self.stftData;
}


@end
