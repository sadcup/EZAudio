//
//  EZAudioSpectralPlot.m
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

#import "EZAudioSpectralPlot.h"
#import "EZAudioDisplayLink.h"

//------------------------------------------------------------------------------
#pragma mark - Constants
//------------------------------------------------------------------------------

#define WIDTH  1024
#define HEIGHT 128

UInt32 const EZAudioSpectralPlotDefaultHistoryBufferLength = 512;
UInt32 const EZAudioSpectralPlotDefaultMaxHistoryBufferLength = 8192;

//------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlot (Interface Extension)
//------------------------------------------------------------------------------

@interface EZAudioSpectralPlot () <EZAudioDisplayLinkDelegate>
@property (nonatomic, strong) EZAudioDisplayLink *displayLink;

@property (nonatomic, assign) CGPoint            *points;
@property (nonatomic, assign) UInt32              pointCount;

@end

//------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlot (Implementation)
//------------------------------------------------------------------------------

@implementation EZAudioSpectralPlot

//------------------------------------------------------------------------------
#pragma mark - Dealloc
//------------------------------------------------------------------------------

- (void)dealloc
{
    free(self.points);
}

//------------------------------------------------------------------------------
#pragma mark - Initialization
//------------------------------------------------------------------------------

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initPlot];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initPlot];
    }
    return self;
}

#if TARGET_OS_IPHONE
- (id)initWithFrame:(CGRect)frameRect
#elif TARGET_OS_MAC
- (id)initWithFrame:(NSRect)frameRect
#endif
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        [self initPlot];
    }
    return self;
}

#if TARGET_OS_IPHONE
- (void)layoutSubviews
{
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    //self.spectrogramLayer.frame = self.bounds;
    
    
    //[self redraw];
    [CATransaction commit];
}
#elif TARGET_OS_MAC
- (void)layout
{
    [super layout];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.waveformLayer.frame = self.bounds;
    //[self redraw];
    [CATransaction commit];
}
#endif

- (void)initPlot
{

    //self.shouldOptimizeForRealtimePlot = YES;
    //self.shouldOptimizeForRealtimePlot = NO;
    
    self.gain = 1.0;
    self.plotType = EZPlotTypeBuffer;
    self.shouldMirror = NO;
    self.shouldFill = NO;
    
    // Setup history window
    [self resetHistoryBuffers];
    
    //self.spectrogramLayer = [[EZAudioSpectralPlotWaveformLayer alloc] initWithWidth:512 height:512];
    //self.spectrogramLayer.frame = self.bounds;

    //self.spectrogramLayer.opaque = YES;
    
    //self.spectrogramLayer.rollingBufferLength = 32 * 1024;
    
    //NSLog(@"%@", self.spectrogramLayer.imagContext);
    
    self.backgroundColor = nil;
    
    //[self.layer insertSublayer:self.spectrogramLayer atIndex:0];
    
    [self setupPlot];
    
    //self.points = calloc(EZAudioSpectralPlotDefaultMaxHistoryBufferLength, sizeof(CGPoint));
    //self.pointCount = [self initialPointCount];
    
    //self.stft = [[EZAudioSTFT alloc] initWithBufferSize:1024 fftSize:128 sampleRate:0.0 delegate:self];

    
    self.data = calloc(WIDTH * HEIGHT, sizeof(UInt32));
    self.layerArray = [[NSMutableArray alloc] init];
    self.counter = 0;
    self.frameCounter = 0;
    
    //[self redraw];
}

//------------------------------------------------------------------------------

- (void)setupPlot
{

}

//------------------------------------------------------------------------------
#pragma mark - Setup
//------------------------------------------------------------------------------

- (void)resetHistoryBuffers
{
}

//------------------------------------------------------------------------------
#pragma mark - Setters
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------

- (void)setShouldOptimizeForRealtimePlot:(BOOL)shouldOptimizeForRealtimePlot
{
    _shouldOptimizeForRealtimePlot = shouldOptimizeForRealtimePlot;
    if (shouldOptimizeForRealtimePlot && !self.displayLink)
    {
        self.displayLink = [EZAudioDisplayLink displayLinkWithDelegate:self];
        [self.displayLink start];
    }
    else
    {
        [self.displayLink stop];
        self.displayLink = nil;
    }
}

//------------------------------------------------------------------------------

- (void)setShouldFill:(BOOL)shouldFill
{
    [super setShouldFill:shouldFill];
}

//------------------------------------------------------------------------------
#pragma mark - Drawing
//------------------------------------------------------------------------------

- (void)clear
{
    if (self.pointCount > 0)
    {
        [self resetHistoryBuffers];
        float data[self.pointCount];
        memset(data, 0, self.pointCount * sizeof(float));
        [self setSampleData:data length:self.pointCount];
        //[self redraw];
    }
}

#pragma mark - Time Frequency Representation

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )
#define COLORMAPSIZE 64
const unsigned int colormap_r[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,15,31,47,63,79,95,111,127,143,159,175,191,207,223,239,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,239,223,207,191,175,159,143,127};
const unsigned int colormap_g[] = {0,0,0,0,0,0,0,0,15,31,47,63,79,95,111,127,143,159,175,191,207,223,239,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,239,223,207,191,175,159,143,127,111,95,79,63,47,31,15,0,0,0,0,0,0,0,0,0};
const unsigned int colormap_b[] = {143,159,175,191,207,223,239,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,239,223,207,191,175,159,143,127,111,95,79,63,47,31,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

- (void)redraw {
    
    if (abs(self.counter-self.frameCounter) == 0) {
        return;
    }
    
    UInt32 width = WIDTH/128;
    float ratio = self.bounds.size.width / WIDTH;
    
    int width1 = width * ratio;
    
    //UInt32 * newData = self.data + self.counter * width1 * HEIGHT;
    UInt32 * thisData = self.data + self.frameCounter * width1 * HEIGHT;
    
    int frameWidth = width * (self.counter - self.frameCounter + WIDTH/width) % (WIDTH/width);
    int frameWidth1 =  width1 * (self.counter - self.frameCounter + WIDTH/width) % (WIDTH/width);
    
    NSLog(@"update length %d", frameWidth1);
    
    EZAudioSpectralPlotWaveformLayer * newLayer = [[EZAudioSpectralPlotWaveformLayer alloc] initWithData:thisData width:frameWidth height:HEIGHT];
    newLayer.frame = CGRectMake(self.bounds.size.width, 0, frameWidth1, self.bounds.size.height);
    [self.layerArray addObject:newLayer];
    [self.layer addSublayer:newLayer];
    [newLayer setNeedsDisplay];
    
    NSMutableIndexSet * toBeDelete = [[NSMutableIndexSet alloc] init];
    
    for(int i = 0; i< self.layerArray.count; i++) {
        
        EZAudioSpectralPlotWaveformLayer * lay = self.layerArray[i];
        
        //if (lay.frame.origin.x + lay.frame.size.width < -width) {
        if (lay.position.x + frameWidth1 < 0) {
            [lay removeFromSuperlayer];
            [toBeDelete addIndex:i];
        }
        
        lay.position = CGPointMake(lay.position.x - frameWidth1, lay.position.y);
        
    }
    
    
    [self.layerArray removeObjectsAtIndexes:toBeDelete];
    
    self.frameCounter = self.counter;
    
    
}

- (void)redrawWithBuffer:(float *)buffer {
    

    
    
//    EZAudioSpectralPlotWaveformLayer * newLayer = [[EZAudioSpectralPlotWaveformLayer alloc] initWithData:newData width:width height:HEIGHT];
//    newLayer.frame = CGRectMake(self.bounds.size.width + width1, 0, width1, self.bounds.size.height);
//    
//    NSLog(@"current view's width %f height %f", self.bounds.size.width, self.bounds.size.height);
//    
//    [self.layerArray addObject:newLayer];
//    [self.layer addSublayer:newLayer];
//    //[newLayer setNeedsDisplay];
//    
//    
//    NSMutableIndexSet * toBeDelete = [[NSMutableIndexSet alloc] init];
//    
//    for(int i = 0; i< self.layerArray.count; i++) {
//        
//        EZAudioSpectralPlotWaveformLayer * lay = self.layerArray[i];
//        
//        //if (lay.frame.origin.x + lay.frame.size.width < -width) {
//        if (lay.position.x + 2 *width1 < 0) {
//            [lay removeFromSuperlayer];
//            [toBeDelete addIndex:i];
//        }
//        
//        lay.position = CGPointMake(lay.position.x - width1, lay.position.y);
//
//    }
//    
//    
//    [self.layerArray removeObjectsAtIndexes:toBeDelete];
    
    

    
}




//------------------------------------------------------------------------------
#pragma mark - Update
//------------------------------------------------------------------------------

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize
{
    
    // copy samples
    switch (self.plotType)
    {
        case EZPlotTypeBuffer:
            [self setSampleData:buffer
                         length:bufferSize];
            break;
        case EZPlotTypeRolling:
            
            break;
        default:
            break;
    }
    
    UInt32 width = WIDTH/128;
    float ratio = self.bounds.size.width / WIDTH;
    
    int width1 = width * ratio;
    
    UInt32 * newData = self.data + self.counter * width1 * HEIGHT;
    
    
    float timeStep = (float)1024/8 / width;
    float freqStep = (float)128 / HEIGHT;
    
    int localWidth = timeStep < 1 ? 1 : timeStep;
    int localHeight = freqStep < 1 ? 1 : freqStep;
    
    
    for (int i = 0; i<width; i++) {
        for (int j=0; j<HEIGHT; j++) {
            // find the local matrix and extract it into one point.
            int originx = i * timeStep;
            int originy = j * freqStep;
            
            float mean = 0.0;
            
            mean = buffer[originx*128+originy];
            
            //            for (int ii = 0; ii<localWidth; ii++) {
            //                for (int jj = 0; jj<localHeight; jj++) {
            //                    mean += buffer[(originx+ii)*128 + (originy+jj)];
            //                }
            //            }
            //            mean /= (localWidth * localHeight);
            
            
            
            int colorIdx = (mean * COLORMAPSIZE);
            
            if (colorIdx >= COLORMAPSIZE) colorIdx=COLORMAPSIZE-1;
            if (colorIdx < 0) colorIdx = 0;
            
            UInt32 newR = colormap_r[colorIdx];
            UInt32 newG = colormap_g[colorIdx];
            UInt32 newB = colormap_b[colorIdx];
            
            //Clamp, not really useful here :p
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            //newData[i*HEIGHT + j] = RGBAMake(newR, newG, newB, 0xFF);
            newData[j*width + i] = RGBAMake(newR, newG, newB, 0xFF);
            
        }
    }

    
    //[self redrawWithBuffer:buffer];
    
    
    self.counter++;
    self.counter %= WIDTH/width;
    
    [self redraw];
    
    // update drawing
    //if (!self.shouldOptimizeForRealtimePlot)
    //{
    //    [self redraw];
    //}
    
}

//------------------------------------------------------------------------------

- (void)setSampleData:(float *)data length:(int)length
{
//    CGPoint *points = self.points;
//    for (int i = 0; i < length; i++)
//    {
//        points[i].x = i;
//        points[i].y = data[i] * self.gain;
//    }
//    points[0].y = points[length - 1].y = 0.0f;
//    self.pointCount = length;
    
    
}

- (void)setSampleData:(float *)data width:(int)width height:(int)height {
    
}

//------------------------------------------------------------------------------
#pragma mark - Adjusting History Resolution
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
#pragma mark - Subclass
//------------------------------------------------------------------------------

- (int)defaultRollingHistoryLength
{
    return EZAudioSpectralPlotDefaultHistoryBufferLength;
}

//------------------------------------------------------------------------------

- (int)initialPointCount
{
    return 1024;
}

//------------------------------------------------------------------------------

- (int)maximumRollingHistoryLength
{
    return EZAudioSpectralPlotDefaultMaxHistoryBufferLength;
}

//------------------------------------------------------------------------------
#pragma mark - Utility
//------------------------------------------------------------------------------

- (BOOL)isDeviceOriginFlipped
{
    BOOL isDeviceOriginFlipped = NO;
#if TARGET_OS_IPHONE
    isDeviceOriginFlipped = YES;
#elif TARGET_OS_MAC
#endif
    return isDeviceOriginFlipped;
}

//------------------------------------------------------------------------------
#pragma mark - EZAudioDisplayLinkDelegate
//------------------------------------------------------------------------------

- (void)displayLinkNeedsDisplay:(EZAudioDisplayLink *)displayLink
{
    NSLog(@"will call redraw from displayLinkNeedsDisplay.");
    //[self redraw];
}


@end

////------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlotWaveformLayer (Implementation)
////------------------------------------------------------------------------------

@interface EZAudioSpectralPlotWaveformLayer ()

@property (nonatomic, assign) CGImageRef newImage;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;

@end


@implementation EZAudioSpectralPlotWaveformLayer


- (instancetype)initWithData:(UInt32 *)data width:(int)width height:(int)height {
    self = [super init];
    if (self) {
        //_data = calloc(width * height, sizeof(UInt32));
        //memcpy(_data, data, width*height*sizeof(UInt32));
        
        _width = width;
        _height = height;
        
        CGContextRef context = MyCreateBitmapContext(self.width, self.height);
        
        UInt32 * bitmapData = CGBitmapContextGetData(context);
        for (int i=0; i<self.height; i++) {
            for (int j=0; j<self.width; j++) {
                bitmapData[i*self.width+j] = data[i*self.width + j];
            }
        }
        
        self.newImage = CGBitmapContextCreateImage(context);
        
        free(bitmapData);
        CGContextRelease(context);
        
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    CGContextDrawImage(ctx, self.bounds, self.newImage);
    //CGImageRelease(self.newImage);
}

CGContextRef MyCreateBitmapContext (int pixelsWide, int pixelsHigh) {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    bitmapData = calloc ( bitmapByteCount, 1);
    if (bitmapData == NULL) {
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedLast);
    if (context== NULL) {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );
    return context;
}


- (void)dealloc {
    //free(self.data);
    CGImageRelease(self.newImage);
}

@end