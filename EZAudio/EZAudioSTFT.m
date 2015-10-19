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

- (instancetype)initWithBufferSize:(vDSP_Length)bufferSize sampleRate:(float)sampleRate delegate:(id<EZAudioSTFTDelegate>)delegate {
    self = [super init];
    if (self) {
        //
        // Create an instance of the EZAudioFFTRolling to keep a history of the incoming audio data and calculate the FFT.
        //
        self.fft = [EZAudioFFTRolling fftWithWindowSize:bufferSize
                                             sampleRate:sampleRate
                                               delegate:self];
        self.bufferSize = bufferSize;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.stftData = malloc(256 * self.bufferSize * sizeof(float));
}
- (void)dealloc {
    free(self.stftData);
}

- (float *)computeSTFTWithBuffer:(float *)buffer
                  withBufferSize:(UInt32)bufferSize
{
    if (buffer == NULL)
    {
        return NULL;
    }
    
    int fftSize = 256;
    float sink[256];
    int windowLength = 30;
    
    for (int i=0; i<bufferSize; i++) {
        
        for (int j=0; j<windowLength; j++) {
            if (i+j < bufferSize) {
                sink[j] = buffer[i+j];
            } else {
                sink[j] = 0.0;
            }
        }
        
        float * fftData = [self.fft computeFFTWithBuffer:sink withBufferSize:fftSize];
        
        for (int k=0; k<fftSize; k++) {
            self.stftData[i*bufferSize + k] = fftData[k];
        }
    }
    
    return self.stftData;
}


@end
