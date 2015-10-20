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
        
        self.windowsLength = 27;
        self.windows = gausswin(self.windowsLength, 2.5);
        self.localBuffer = initLocalBuffer(self.windowsLength);

    }
    return self;
}

- (void)dealloc {
    free(self.stftData);
    free(self.fftSink);
    free(self.windows);
    free(self.localBuffer);
}

float * gausswin(int N, float alpha) {
    float stdev = (float)(N-1)/(2*alpha);
    float offset = -(float)(N-1)/2;
    float * win = calloc(N, sizeof(float));
    for (int i=0; i<N; i++) {
        float coef = (i+offset) / stdev;
        win[i] = expf(-0.5 * powf(coef, 2.0));
    }
    return win;
}

float * initLocalBuffer(int len) {
    float * buffer = calloc(len, sizeof(float));
    for (int i=0; i<len; i++) {
        buffer[i] = 0.0;
    }
    return buffer;
}

- (float *)computeSTFTWithBuffer:(float *)buffer
                  withBufferSize:(UInt32)bufferSize {
    
    if (buffer == NULL)
    {
        return NULL;
    }
    
    float * pool = calloc(bufferSize + self.windowsLength, sizeof(float));

    memcpy(pool, self.localBuffer, self.windowsLength*sizeof(float));
    memcpy(pool+self.windowsLength, buffer, bufferSize*sizeof(float));
    memcpy(self.localBuffer, buffer+bufferSize-self.windowsLength, self.windowsLength*sizeof(float));
    
    float maxValue = CGFLOAT_MIN;
    
    for (int i = 0; i < bufferSize; i++) {

        for (int j = 0; j < self.windowsLength; j++) {
            if (i+j < bufferSize) {
                self.fftSink[j] = pool[i+j] * self.windows[j];
            } else {
                self.fftSink[j] = 0.0;
            }
        }
        
        float * fftData = [self.fft computeFFTWithBuffer:self.fftSink withBufferSize:self.fftSize];
        int fftDataLength = self.fftSize/2;
        
        for (int k=0; k<fftDataLength; k++) {
            
            float thisValue = powf(fftData[k], 1.0);//fabs(fftData[k]);
            
            if ( thisValue > maxValue) {
                maxValue = thisValue;
            }
            
            self.stftData[i * fftDataLength + k] = thisValue;
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
    
    /**
     *  Free the temporary memory
     */
    free(pool);
    
    return self.stftData;
}


@end
