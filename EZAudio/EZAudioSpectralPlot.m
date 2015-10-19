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

UInt32 const kEZAudioSpectralPlotMaxHistoryBufferLength = 8192;
UInt32 const kEZAudioSpectralPlotDefaultHistoryBufferLength = 512;
UInt32 const EZAudioSpectralPlotDefaultHistoryBufferLength = 512;
UInt32 const EZAudioSpectralPlotDefaultMaxHistoryBufferLength = 8192;

//------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlot (Interface Extension)
//------------------------------------------------------------------------------

@interface EZAudioSpectralPlot () <EZAudioDisplayLinkDelegate>
@property (nonatomic, strong) EZAudioDisplayLink *displayLink;
@property (nonatomic, assign) EZPlotHistoryInfo  *historyInfo;
@property (nonatomic, assign) CGPoint            *points;
@property (nonatomic, assign) UInt32              pointCount;

@property (nonatomic, assign) UIImage * image;

@end

//------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlot (Implementation)
//------------------------------------------------------------------------------

@implementation EZAudioSpectralPlot
- (UIImage *)image {
    if (!_image) {
        _image = [UIImage imageNamed:@"test.bmp"];
    }
    return _image;
}
//------------------------------------------------------------------------------
#pragma mark - Dealloc
//------------------------------------------------------------------------------

- (void)dealloc
{
    [EZAudioUtilities freeHistoryInfo:self.historyInfo];
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
    
    self.spectrogramLayer.frame = self.bounds;
    
    //self.spectrogramLayer.frame = CGRectMake(0, 0, self.bounds.size.width/2, self.bounds.size.height/2);
    
    
    [self redraw];
    [CATransaction commit];
}
#elif TARGET_OS_MAC
- (void)layout
{
    [super layout];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.waveformLayer.frame = self.bounds;
    [self redraw];
    [CATransaction commit];
}
#endif

- (void)initPlot
{
    self.shouldCenterYAxis = YES;
    self.shouldOptimizeForRealtimePlot = YES;
    self.gain = 1.0;
    self.plotType = EZPlotTypeBuffer;
    self.shouldMirror = NO;
    self.shouldFill = NO;
    
    // Setup history window
    [self resetHistoryBuffers];
    
    self.spectrogramLayer = [EZAudioSpectralPlotWaveformLayer layer];
    self.spectrogramLayer.frame = self.bounds;
    //self.waveformLayer.lineWidth = 1.0f;
    //self.waveformLayer.fillColor = nil;
    //self.spectrogramLayer.backgroundColor = nil;
    self.spectrogramLayer.opaque = YES;
    NSLog(@"%@", self.spectrogramLayer.imagContext);
    
#if TARGET_OS_IPHONE
    self.color = [UIColor colorWithHue:0 saturation:1.0 brightness:1.0 alpha:1.0]; 
#elif TARGET_OS_MAC
    self.color = [NSColor colorWithCalibratedHue:0 saturation:1.0 brightness:1.0 alpha:1.0];
    self.wantsLayer = YES;
    //self.wantsUpdateLayer = YES;
    
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
#endif
    self.backgroundColor = nil;
    
    [self.layer insertSublayer:self.spectrogramLayer atIndex:0];
    
    //
    // Allow subclass to initialize plot
    //
    [self setupPlot];
    
    self.points = calloc(EZAudioSpectralPlotDefaultMaxHistoryBufferLength, sizeof(CGPoint));
    self.pointCount = [self initialPointCount];
    
    self.stft = [[EZAudioSTFT alloc] initWithBufferSize:self.pointCount sampleRate:0.0 delegate:self];

    
    [self redraw];
}

//------------------------------------------------------------------------------

- (void)setupPlot
{
    //
    // Override in subclass
    //
}

//------------------------------------------------------------------------------
#pragma mark - Setup
//------------------------------------------------------------------------------

- (void)resetHistoryBuffers
{
    //
    // Clear any existing data
    //
    if (self.historyInfo)
    {
        [EZAudioUtilities freeHistoryInfo:self.historyInfo];
    }
    
    self.historyInfo = [EZAudioUtilities historyInfoWithDefaultLength:[self defaultRollingHistoryLength]
                                                        maximumLength:[self maximumRollingHistoryLength]];
}

//------------------------------------------------------------------------------
#pragma mark - Setters
//------------------------------------------------------------------------------

- (void)setBackgroundColor:(id)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.layer.backgroundColor = [backgroundColor CGColor];
}

//------------------------------------------------------------------------------

- (void)setColor:(id)color
{
    [super setColor:color];
    //self.waveformLayer.strokeColor = [color CGColor];
    if (self.shouldFill)
    {
        //self.waveformLayer.fillColor = [color CGColor];
    }
}

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
    //self.waveformLayer.fillColor = shouldFill ? [self.color CGColor] : nil;
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
        
        
        [self redraw];
    }
}

//------------------------------------------------------------------------------
//- (void)drawRect:(NSRect)dirtyRect {
//- (void)drawRect:(CGRect)rect {
//    NSLog(@"drawRect is called");
//    
//    //CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGRect boundingBox = CGRectMake(150, 0, 100, self.bounds.size.height);
//    
//    float * stftData = calloc(256 * self.pointCount, sizeof(float));
//    for (int i=0; i<256*self.pointCount; i++) {
//        //stftData[i] = (arc4random() % 1000)/1000;
//        stftData[i] = (float)(arc4random() % 1000)/1000;
//    }
//    
//    
//    CGImageRef cgImage = [self imageOfTFR:stftData width:self.pointCount heigth:256];
//    
//    CGContextDrawImage(context, boundingBox, cgImage);
//    
//    //    CGContextRef bitmapContext = MyCreateBitmapContext(self.pointCount, 256);
//    //    char * bitmapData = CGBitmapContextGetData(bitmapContext);
//    //    if (bitmapData) {
//    //        free(bitmapData);
//    //    }
//    //    CGContextRelease(bitmapContext);
//    
//    free(stftData);
//    CGImageRelease(cgImage);
//
//}

//- (void)updateLayer {
//    NSLog(@"updateLayer is called");
//}

//- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
//    NSLog(@"2-The delegate method is called.");
//    
//    CGContextSaveGState(ctx);
//    CGFloat drawWidthRatio = 0.2;
//    CGFloat drawHeightRatio = 1.0;
//    CGFloat drawWidth = self.bounds.size.width * drawWidthRatio;
//    CGFloat drawHeight = self.bounds.size.height * drawHeightRatio;
//    CGRect drawArea = CGRectMake(self.bounds.size.width-drawWidth, 0, drawWidth, drawHeight);
//
//    CGRect rect = self.bounds;
//    CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
//    CGContextTranslateCTM(ctx, 0, rect.size.height);
//    CGContextScaleCTM(ctx, 1.0, -1.0);
//    CGContextTranslateCTM(ctx, -rect.origin.x, -rect.origin.y);
//    
//    
//    //CGContextScaleCTM(ctx, 1, -1);
//    //CGContextTranslateCTM(ctx, 0, -drawHeight);
//
//    //NSImage * image =[NSImage imageNamed:@"test"];
//    //CGImageRef cgImage = [self NSImageToCGImageRef:image];
//    CGImageRef cgImage = self.image.CGImage;//[UIImage imageNamed:@"test.bmp"].CGImage;
//
//    CGContextDrawImage(ctx, drawArea, cgImage);
//    CGImageRelease(cgImage);
//    CGContextRestoreGState(ctx);
//
//}
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
    //NSLog(@"---------------------------------------");
    //NSLog(@"1-redraw is called.");
    //[self.layer setNeedsDisplay];
    //self.spectrogramLayer.backgroundColor = [UIColor blueColor].CGColor;
    //[self.spectrogramLayer setNeedsDisplay];
    
    //self.waveformLayer.position  = CGPointMake(self.waveformLayer.position.x + 1, self.waveformLayer.position.y);
    //[self setNeedsDisplay:YES];
    //self.waveformLayer.position = CGPointMake(self.waveformLayer.position.x+1, self.waveformLayer.position.y);
    //[self.waveformLayer setNeedsDisplay];
    
    float * tmpData = malloc(self.pointCount * sizeof(float));
    for (int i=0; i<self.pointCount; i++) {
        tmpData[i] = self.points[i].y;
        //tmpData[i] = sinf(2 * M_PI * 5000 * i / 44100);
    }
    
    float * stftData = [self.stft computeSTFTWithBuffer:tmpData withBufferSize:self.pointCount];
    
    float maxValue = CGFLOAT_MIN;
    for (int i=0; i<1024; i++) {
        for (int j=0; j<256; j++) {
            if (stftData[i*1024+j] > maxValue) {
                maxValue = stftData[i*1024+j];
            }
        }
    }
    
    free(tmpData);
    
//    UInt32 * from = self.spectrogramLayer.data + 1024 * 256;
//    UInt32 * to = self.spectrogramLayer.data;
//    for (int i=0; i<9; i++) {
//        memcpy(to, from, 1024 * 256 *sizeof(UInt32));
//        to += 1024 * 256;
//        from += 1024 * 256;
//    }

    memcpy(self.spectrogramLayer.data, self.spectrogramLayer.data+1024 * 256, 1024 * 256 * 9 * sizeof(UInt32));
    
    
    UInt32 * newData = self.spectrogramLayer.data + 9 * 1024 * 256;
    
    for (int i=0; i<1024; i++) {
        for (int j=0; j<256; j++) {
            //self.spectrogramLayer.data[i*1024 + j] = stftData[i*1024 + j];
            
            int colorIdx = (stftData[i*256+j]/maxValue * COLORMAPSIZE);
            
            if (colorIdx >= COLORMAPSIZE) colorIdx=COLORMAPSIZE-1;
            if (colorIdx < 0) colorIdx = 0;
            
            UInt32 newR = colormap_r[colorIdx];
            UInt32 newG = colormap_g[colorIdx];
            UInt32 newB = colormap_b[colorIdx];
            
            //Clamp, not really useful here :p
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            //*inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
            newData[i*256 + j] = RGBAMake(newR, newG, newB, 0xFF);
            
        }
    }
    
    [self.spectrogramLayer setNeedsDisplay];
    
}



- (CGImageRef)imageOfTFR:(float *)tfr width:(NSUInteger)width heigth:(NSUInteger)height {
    UInt32 * pixels;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    
    NSUInteger bytesPerRow = bytesPerPixel * width;
    
    pixels = (UInt32 *)calloc(height * width, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    
    //Set each pixel
    for (NSUInteger i = 0; i < width; i++) {
        for (NSUInteger j = 0; j < height; j++) {
            
            UInt32 * inputPixel = pixels + j * width + i;
            //UInt32 inputColor = (UInt32)(self.tfr[j * width + i]);
            
            //UInt32 newR = R(inputColor);
            //UInt32 newG = G(inputColor);
            //UInt32 newB = B(inputColor);
            
            //int colorIdx = (tfr[i*height + j ] * COLORMAPSIZE);
            int colorIdx = (tfr[i*height + height-j] * COLORMAPSIZE);
            
            if (colorIdx >= COLORMAPSIZE) colorIdx=COLORMAPSIZE-1;
            if (colorIdx < 0) colorIdx = 0;
            
            UInt32 newR = colormap_r[colorIdx];
            UInt32 newG = colormap_g[colorIdx];
            UInt32 newB = colormap_b[colorIdx];
            
            //Clamp, not really useful here :p
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            //*inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
            *inputPixel = RGBAMake(newR, newG, newB, 0xFF);
        }
    }
    
    return CGBitmapContextCreateImage(context);
    
//    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
//    UIImage * image = [UIImage imageWithCGImage:newCGImage];
//    
//    CGColorSpaceRelease(colorSpace);
//    CGContextRelease(context);
//    free(pixels);
//    
//    
//    return image;
    
}

- (CGContextRef)contextOfTFR:(float *)tfr width:(NSUInteger)width heigth:(NSUInteger)height {
    UInt32 * pixels;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    
    NSUInteger bytesPerRow = bytesPerPixel * width;
    
    pixels = (UInt32 *)calloc(height * width, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    
    //Set each pixel
    for (NSUInteger i = 0; i < width; i++) {
        for (NSUInteger j = 0; j < height; j++) {
            
            UInt32 * inputPixel = pixels + j * width + i;
            //UInt32 inputColor = (UInt32)(self.tfr[j * width + i]);
            
            //UInt32 newR = R(inputColor);
            //UInt32 newG = G(inputColor);
            //UInt32 newB = B(inputColor);
            
            //int colorIdx = (tfr[i*height + j ] * COLORMAPSIZE);
            int colorIdx = (tfr[i*height + height-j] * COLORMAPSIZE);
            
            if (colorIdx >= COLORMAPSIZE) colorIdx=COLORMAPSIZE-1;
            if (colorIdx < 0) colorIdx = 0;
            
            UInt32 newR = colormap_r[colorIdx];
            UInt32 newG = colormap_g[colorIdx];
            UInt32 newB = colormap_b[colorIdx];
            
            //Clamp, not really useful here :p
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            //*inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
            *inputPixel = RGBAMake(newR, newG, newB, 0xFF);
        }
    }
    return context;
}


//- (void)redraw
//{
//    EZRect frame = [self.waveformLayer frame];
//    CGPathRef path = [self createPathWithPoints:self.points
//                                     pointCount:self.pointCount
//                                         inRect:frame];
//    if (self.shouldOptimizeForRealtimePlot)
//    {
//        [CATransaction begin];
//        [CATransaction setDisableActions:YES];
//        self.waveformLayer.path = path;
//        [CATransaction commit];
//    }
//    else
//    {
//        self.waveformLayer.path = path;
//    }
//    CGPathRelease(path);
//}

//------------------------------------------------------------------------------

- (CGPathRef)createPathWithPoints:(CGPoint *)points
                  pointCount:(UInt32)pointCount
                      inRect:(EZRect)rect
{
    CGMutablePathRef path = NULL;
    if (pointCount > 0)
    {
        path = CGPathCreateMutable();
        double xscale = (rect.size.width) / ((float)self.pointCount);
        double halfHeight = floor(rect.size.height / 2.0);
        int deviceOriginFlipped = [self isDeviceOriginFlipped] ? -1 : 1;
        CGAffineTransform xf = CGAffineTransformIdentity;
        CGFloat translateY = 0.0f;
        if (!self.shouldCenterYAxis)
        {
#if TARGET_OS_IPHONE
            translateY = CGRectGetHeight(rect);
#elif TARGET_OS_MAC
            translateY = 0.0f;
#endif
        }
        else
        {
            translateY = halfHeight + rect.origin.y;
        }
        xf = CGAffineTransformTranslate(xf, 0.0, translateY);
        double yScaleFactor = halfHeight;
        if (!self.shouldCenterYAxis)
        {
            yScaleFactor = 2.0 * halfHeight;
        }
        xf = CGAffineTransformScale(xf, xscale, deviceOriginFlipped * yScaleFactor);
        CGPathAddLines(path, &xf, self.points, self.pointCount);
        if (self.shouldMirror)
        {
            xf = CGAffineTransformScale(xf, 1.0f, -1.0f);
            CGPathAddLines(path, &xf, self.points, self.pointCount);
        }
        if (self.shouldFill)
        {
            CGPathCloseSubpath(path);
        }
    }
    return path;
}

//------------------------------------------------------------------------------
#pragma mark - Update
//------------------------------------------------------------------------------

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize
{
    // append the buffer to the history
    [EZAudioUtilities appendBufferRMS:buffer
                       withBufferSize:bufferSize
                        toHistoryInfo:self.historyInfo];
    
    // copy samples
    switch (self.plotType)
    {
        case EZPlotTypeBuffer:
            [self setSampleData:buffer
                         length:bufferSize];
            break;
        case EZPlotTypeRolling:
            
            [self setSampleData:self.historyInfo->buffer
                         length:self.historyInfo->bufferSize];
            break;
        default:
            break;
    }
    
    // update drawing
    if (!self.shouldOptimizeForRealtimePlot)
    {
        [self redraw];
    }
}

//------------------------------------------------------------------------------

- (void)setSampleData:(float *)data length:(int)length
{
    CGPoint *points = self.points;
    for (int i = 0; i < length; i++)
    {
        points[i].x = i;
        points[i].y = data[i] * self.gain;
    }
    points[0].y = points[length - 1].y = 0.0f;
    self.pointCount = length;
}

//------------------------------------------------------------------------------
#pragma mark - Adjusting History Resolution
//------------------------------------------------------------------------------

- (int)rollingHistoryLength
{
    return self.historyInfo->bufferSize;
}

//------------------------------------------------------------------------------

- (int)setRollingHistoryLength:(int)historyLength
{
    self.historyInfo->bufferSize = MIN(EZAudioSpectralPlotDefaultMaxHistoryBufferLength, historyLength);
    return self.historyInfo->bufferSize;
}

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
    return 100;
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
    [self redraw];
}


//- (void)drawRect:(NSRect)dirtyRect {
//    CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
//    CGRect myBoundingBox;// 1
//    int myWidth = 500;
//    int myHeight = 200;
//    myBoundingBox = CGRectMake (0, 0, myWidth, myHeight);// 2
//    CGContextRef myBitmapContext = MyCreateBitmapContext (500, 600);// 3
//
//    // ********** Your drawing code here ********** // 4
//    CGContextSetRGBFillColor (myBitmapContext, 1, 0, 0, 1);
//    CGContextFillRect (myBitmapContext, CGRectMake (0, 0, 200, 100 ));
//    CGContextSetRGBFillColor (myBitmapContext, 0, 0, 1, .5);
//    CGContextFillRect (myBitmapContext, CGRectMake (0, 0, 100, 200 ));
//    CGImageRef  myImage = CGBitmapContextCreateImage (myBitmapContext);// 5
//    CGContextDrawImage(myContext, myBoundingBox, myImage);// 6
//    char *bitmapData = CGBitmapContextGetData(myBitmapContext); // 7
//    CGContextRelease (myBitmapContext);// 8
//    if (bitmapData) free(bitmapData); // 9
//    CGImageRelease(myImage);// 10
//}



@end

////------------------------------------------------------------------------------
#pragma mark - EZAudioSpectralPlotWaveformLayer (Implementation)
////------------------------------------------------------------------------------

@interface EZAudioSpectralPlotWaveformLayer ()

@property (nonatomic, assign) BOOL flag;
@property (nonatomic, assign) int counter;


@end


@implementation EZAudioSpectralPlotWaveformLayer

- (CGContextRef)imagContext {
    if (!_imagContext) {
        _imagContext = MyCreateBitmapContext(256, 10240);
        self.data = CGBitmapContextGetData(_imagContext);
        self.counter = 0;
    }
    return _imagContext;
}


- (void)drawInContext:(CGContextRef)ctx {
    
    CGImageRef  newImage = CGBitmapContextCreateImage(self.imagContext);
    
    CGContextRotateCTM(ctx, -M_PI/2);
    CGContextScaleCTM(ctx, self.bounds.size.height/self.bounds.size.width, self.bounds.size.width/self.bounds.size.height);
    CGContextTranslateCTM(ctx, -self.bounds.size.width, 0);
    CGContextDrawImage(ctx, self.bounds, newImage);
    
    
    CGImageRelease(newImage);
    
}

- (void)dealloc {
    NSLog(@"dealloc of MovingLayer is called.");
    
    
    if (self.imagContext) {
        CGContextRelease(self.imagContext);
    }
    if (self.data) {
        free(self.data);
    }
    
}

//------------------------------------------------------------------------------
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





//- (id<CAAction>)actionForKey:(NSString *)event
//{
//    if ([event isEqualToString:@"path"])
//    {
//        if ([CATransaction disableActions])
//        {
//            return nil;
//        }
//        else
//        {
//            CABasicAnimation *animation = [CABasicAnimation animation];
//            animation.timingFunction = [CATransaction animationTimingFunction];
//            animation.duration = [CATransaction animationDuration];
//            return animation;
//        }
//        return nil;
//    }
//    return [super actionForKey:event];
//}

//- (void)drawInContext:(CGContextRef)ctx {
//    NSLog(@"3-drawInContext:");
//    //NSLog(@"CGContext:%@",ctx);
//    
//
//    CGContextSaveGState(ctx);
//    CGFloat drawWidthRatio = 0.2;
//    CGFloat drawHeightRatio = 1.0;
//    CGFloat drawWidth = self.bounds.size.width * drawWidthRatio;
//    CGFloat drawHeight = self.bounds.size.height * drawHeightRatio;
//    CGRect drawArea = CGRectMake(self.bounds.size.width-drawWidth, 0, drawWidth, drawHeight);
//    
//    CGRect rect = self.bounds;
//    CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
//    CGContextTranslateCTM(ctx, 0, rect.size.height);
//    CGContextScaleCTM(ctx, 1.0, -1.0);
//    CGContextTranslateCTM(ctx, -rect.origin.x, -rect.origin.y);
//    
//    //NSImage * image =[NSImage imageNamed:@"test"];
//    //CGImageRef cgImage = [self NSImageToCGImageRef:image];
//    if (self.flag) {
//        CGImageRef cgImage = [UIImage imageNamed:@"test.bmp"].CGImage;
//        CGContextDrawImage(ctx, drawArea, cgImage);
//    } else {
//        CGImageRef cgImage = [UIImage imageNamed:@"test.jpg"].CGImage;
//        CGContextDrawImage(ctx, drawArea, cgImage);
//    }
//    self.flag = !self.flag;
//    
//    
//    
//    //CGImageRelease(cgImage);
//    CGContextRestoreGState(ctx);

//    CGContextSaveGState(ctx);
//    
//    CGContextSetRGBFillColor(ctx, 135.0/255.0, 232.0/255.0, 84.0/255.0, 1);
//    CGContextSetRGBStrokeColor(ctx, 135.0/255.0, 232.0/255.0, 84.0/255.0, 1);
//    CGContextMoveToPoint(ctx, 94.5, 33.5);
//    
//    //// Star Drawing
//    CGContextAddLineToPoint(ctx,104.02, 47.39);
//    CGContextAddLineToPoint(ctx,120.18, 52.16);
//    CGContextAddLineToPoint(ctx,109.91, 65.51);
//    CGContextAddLineToPoint(ctx,110.37, 82.34);
//    CGContextAddLineToPoint(ctx,94.5, 76.7);
//    CGContextAddLineToPoint(ctx,78.63, 82.34);
//    CGContextAddLineToPoint(ctx,79.09, 65.51);
//    CGContextAddLineToPoint(ctx,68.82, 52.16);
//    CGContextAddLineToPoint(ctx,84.98, 47.39);
//    CGContextClosePath(ctx);
//    
//    CGContextDrawPath(ctx, kCGPathFillStroke);
//    
//    CGContextRestoreGState(ctx);
//}

//- (CGImageRef)NSImageToCGImageRef:(NSImage*)image {
//    NSData * imageData = [image TIFFRepresentation];
//    CGImageRef imageRef;
//    if(imageData) {
//        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData,  NULL);
//        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
//    }
//    return imageRef;
//}



@end