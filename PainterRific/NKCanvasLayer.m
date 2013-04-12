//
//  NKCanvasLayer.m
//  PainterRific
//
//  Created by Nino Nhexie Kierulf on 11/4/13.
//  Copyright (c) 2013 Kierulf Pte Ltd. All rights reserved.
//

#import "NKCanvasLayer.h"
#import <mach/mach_time.h>


static const CGFloat kPaintLayerMinDistanceSquared = 8; // TODO
static const NSInteger kPaintLayerMaxPoints = 10;  // TODO

@interface NKCanvasLayer()

@property (assign) CGImageRef bitmapImage;
@property (assign) CGMutablePathRef path;


@property (assign) CGColorRef bgColor;
@property (assign) CGFloat lineWidth;
@property (assign) CGColorRef strokeColor;

@property (assign) NSInteger numPoints;
@property (assign) CGPoint previousPoint;
@property (assign) CGPoint currentPoint;
@property (assign) BOOL hasStartedPath;

/* offscreen rendering */
@property (assign) CGContextRef offscreenCacheContext;
@property (assign) void *offscreenCacheBitmap;

@end

@implementation NKCanvasLayer


- (id<CAAction>)actionForKey:(NSString *)event
{
    if([event isEqualToString:@"contents"])
    {
        return nil;
    }
    return [super actionForKey:event];
}

- (void)drawInContext:(CGContextRef)ctx
{
    /* Performance metrics */
    uint64_t drawStart = mach_absolute_time();
    
    CGContextSaveGState(ctx);
    
    /* if we have a bitmap, draw it. Otherwise draw the background color */
    if(_bitmapImage)
    {
        CGContextDrawImage(ctx, self.bounds, _bitmapImage);
    }
    else
    {
        CGContextSetFillColorWithColor(ctx, _bgColor);
        CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx));
    }
    
    if (_path)
    {
        CGContextAddPath(ctx, _path);
        CGContextSetLineWidth(ctx, _lineWidth);
        CGContextSetStrokeColorWithColor(ctx, _strokeColor);
        CGContextSetLineJoin(ctx, kCGLineJoinRound);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextStrokePath(ctx);
    }
    
    /*if we have a single point, draw a circle at that point */
    if(_numPoints == 1)
    {
        CGContextSetFillColorWithColor(ctx, _strokeColor);
        CGContextFillEllipseInRect(ctx,
                                   CGRectMake(_currentPoint.x - _lineWidth * 0.5,
                                              _currentPoint.y - _lineWidth * 0.5,
                                              _lineWidth, _lineWidth));
    }
    
    /* stroke a 1-point wide red rectangle the width of the current clip shape */
    if(YES)// _showUpdateRects
    {
        CGRect clipRect = CGContextGetClipBoundingBox(ctx);
        clipRect = CGRectInset(clipRect, 0.5, 0.5);
        CGContextSetLineWidth(ctx, 1);
        CGContextSetStrokeColorWithColor(ctx, [[UIColor redColor] CGColor]);
        CGContextStrokeRect(ctx, clipRect);
    }
    
    CGContextRestoreGState(ctx);
    
    /* Performance metrics */
    uint64_t drawEnd = mach_absolute_time();
    [self recordPerformanceMetricsWithFrameStart:drawStart end:drawEnd];
    
}

- (void)recordPerformanceMetricsWithFrameStart:(uint64_t)start end:(uint64_t)end
{
    NSLog(@"ms: %qu", end-start);
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _path = CGPathCreateMutable();
        
        /* initialize default values, can be replaced by creator */
        
        _strokeColor = [[UIColor blackColor] CGColor];
        _lineWidth = 5;
        _numPoints = 0;
        
        /* 
         instead of 
         _bgColor = [[UIColor whiteColor] CGColor];
         let code below handle it 
         */
        [self startNewDrawingWithBackgroundColor:[[UIColor whiteColor] CGColor]];
        
    }
    return self;
}



- (void)beginPathAtPoint:(CGPoint)point
{
    [self setHasStartedPath:YES];
    [self setCurrentPoint:point];
    CGPathMoveToPoint(_path, NULL, point.x, point.y);
    _numPoints++;
}

- (void)addNextPoint:(CGPoint)point
{
    assert(_hasStartedPath);
    
    /* check if the point is farther than min dist from previous */
    CGFloat dx = point.x - _currentPoint.x;
    CGFloat dy = point.y - _currentPoint.y;
    
    if(( dx * dx + dy * dy ) < kPaintLayerMinDistanceSquared)
    {
        return;
    }
    
    /* update current and previous points */
    _previousPoint = _currentPoint;
    _currentPoint = point;
    
    /* add the point to our path */
    CGPathAddLineToPoint(_path, NULL, point.x, point.y);
    _numPoints++;
    
    /* flatten the path if it is too long */
    if(_numPoints > kPaintLayerMaxPoints)
    {
        [self flattenPath];
    }
    
    if(YES)// _calcuateUpdatedRects
    {
        /* calculate our dirty rect */
        CGFloat minX = fmin(_previousPoint.x, _currentPoint.x) - _lineWidth * 0.5;
        CGFloat minY = fmin(_previousPoint.y, _currentPoint.y) - _lineWidth * 0.5;
        CGFloat maxX = fmax(_previousPoint.x, _currentPoint.x) + _lineWidth * 0.5;
        CGFloat maxY = fmax(_previousPoint.y, _currentPoint.y) + _lineWidth * 0.5;
        CGRect dirtyRect = CGRectMake(minX, minY, (maxX - minX), (maxY - minY));
        
        [self setNeedsDisplayInRect:dirtyRect];
    }
    
}

- (void)endPath
{
    [self setHasStartedPath:NO];
    CGPathCloseSubpath(_path);
}

- (void)flattenPath
{
    // TODO : use OffscreenBuffer
    CGContextRef ctx = _offscreenCacheContext;
    CGImageRef cacheImage = CGBitmapContextCreateImage(ctx);
    CGImageRelease(_bitmapImage);
    [self setBitmapImage:cacheImage];
    
    /* Reset */
    
    CGPathRelease(_path);
    [self setPath:CGPathCreateMutable()];
    [self setNumPoints:0];
}



- (void)createOffscreenBuffer
{
    ////UIGraphicsBeginImageContextWithOptions(<#CGSize size#>, <#BOOL opaque#>, <#CGFloat scale#>)
    
    // use bounds
    
    CGSize size = self.bounds.size;
    
    int bitmapByteCount;
    int	bitmapBytesPerRow;
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow = (size.width * 4);
    bitmapByteCount = (bitmapBytesPerRow * size.height);
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    _offscreenCacheBitmap = malloc( bitmapByteCount );
    if (_offscreenCacheBitmap == NULL){
        return;
    }
    _offscreenCacheContext = CGBitmapContextCreate (_offscreenCacheBitmap, size.width, size.height, 8, bitmapBytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaNoneSkipFirst);
    return;
    
}

- (void)startNewDrawingWithBackgroundColor:(CGColorRef)bgColor
{
    [self setBitmapImage:nil];
    [self setBgColor:bgColor];
}



@end
