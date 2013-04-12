//
//  NKCanvasView.m
//  PainterRific
//
//  Created by Nino Nhexie Kierulf on 10/4/13.
//  Copyright (c) 2013 Kierulf Pte Ltd. All rights reserved.
//

#import "NKMultiTouchCanvasView.h"
#import <mach/mach_time.h>

#define IS_IPAD	(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

static const CGFloat kMinDistanceSquared = 4;

/**
 The points are buffer
 while the path contains the whole path containing points
 */
@interface TouchInfo : NSObject

@property (assign, nonatomic) CGPoint point0;
@property (assign, nonatomic) CGPoint point1;
@property (assign, nonatomic) CGPoint point2;
@property (assign, nonatomic) CGPoint point3;

@property (strong, nonatomic) UIBezierPath *path;
@property (assign, nonatomic) CGFloat hue;


@end

@implementation TouchInfo

@end


@interface NKMultiTouchCanvasView()

/* Strokes, list of completed paths */
@property (nonatomic, strong) NSMutableArray *strokes;

/* container for strokes, key is touch */
//@property (nonatomic, strong) NSMutableDictionary *touchPaths;
@property (nonatomic, strong) NSMutableDictionary *touchesInfo;

/* bitmap cache */
@property (assign, nonatomic) void *cacheBitmap;
@property (assign, nonatomic) CGContextRef cacheContext;

@end

@implementation NKMultiTouchCanvasView

#pragma mark Initialization

- (void)commonInit
{
    /* We want to draw with multiple fingers, that would be fun */
    [self setMultipleTouchEnabled:YES];
    
    /* Initialize collection stores */
    [self setStrokes:[NSMutableArray array]];
    [self setTouchesInfo:[NSMutableDictionary dictionary]];
    
    [self initContext:self.frame.size];
}

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect]))
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder]))
    {
        [self commonInit];
    }
    return self;
}

- (BOOL) initContext:(CGSize)size {
	
	int bitmapByteCount;
	int	bitmapBytesPerRow;
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow = (size.width * 4);
	bitmapByteCount = (bitmapBytesPerRow * size.height);
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	_cacheBitmap = malloc( bitmapByteCount );
	if (_cacheBitmap == NULL){
		return NO;
	}
	_cacheContext = CGBitmapContextCreate (_cacheBitmap, size.width, size.height, 8, bitmapBytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaNoneSkipFirst);
	return YES;
}


#pragma mark Private


#pragma mark Public

- (void) clear
{
    [_strokes removeAllObjects];
    [self setNeedsDisplay];
}

#pragma mark UIResponder

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event
{
	for (UITouch *touch in touches)
	{
		NSString *key        = [NSString stringWithFormat:@"%d", (int) touch];
		CGPoint currentPoint = [touch locationInView:self];
		
		UIBezierPath *path   = [UIBezierPath bezierPath];
		path.lineWidth       = IS_IPAD ? 8: 4;
        path.lineCapStyle    = kCGLineCapRound;
		[path moveToPoint:currentPoint];
        
        TouchInfo *touchInfo = [TouchInfo new];
        
        touchInfo.path   = path;
        touchInfo.point0 = CGPointMake(-1, -1);
        touchInfo.point1 = CGPointMake(-1, -1);
        touchInfo.point2 = CGPointMake(-1, -1);
        touchInfo.point3 = currentPoint;
        
        touchInfo.hue = 0.0;
        
        /* create or replace buffer */
        _touchesInfo[key] = touchInfo;
	}
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event
{
    // TODO: use operation to calculate and draw
    
	for (UITouch *touch in touches)
	{
        CGPoint previousPoint = [touch previousLocationInView:self];
        CGPoint currentPoint  = [touch locationInView:self];
        
        if(NO) /* skip if distance is too near */
        {
            /* check if the point is farther than min dist from previous */
            CGFloat dx = fabsf(currentPoint.x - previousPoint.x);
            CGFloat dy = fabsf(currentPoint.y - previousPoint.y);
            
            NSLog(@"dx : %f", dx);
            NSLog(@"dy : %f", dy);
            NSLog(@"dx + dy : %f", dx + dy);
            
            if( ( dx + dy ) < kMinDistanceSquared) return;
        }
        
        /* key is like our address for a specific finger */
		NSString *key      = [NSString stringWithFormat:@"%d", (int) touch];
        TouchInfo *touchInfo = _touchesInfo[key];
        
        /* skip this touch and process the next */
        if (!touchInfo) continue;
		
        /* Update the touch info we are managing 
           and pass the values of point(n) to point(n - 1) */
        touchInfo.point0 = touchInfo.point1;
        touchInfo.point1 = touchInfo.point2;
        touchInfo.point2 = touchInfo.point3;
        touchInfo.point3 = currentPoint;
        
        [self drawForKey:key];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *touch in touches)
	{
		NSString *key = [NSString stringWithFormat:@"%d", (int) touch];
        TouchInfo *touchInfo = _touchesInfo[key];
        
        UIBezierPath *path = touchInfo.path;
        if (path) [_strokes addObject:path];
        
        [_touchesInfo removeObjectForKey:key];
	}
    
    [self setNeedsDisplay];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}

#pragma mark Draw

/* this is where the magic starts */
- (void)drawForKey:(NSString *)key
{
    /* get our buffer */
    TouchInfo *touchInfo = _touchesInfo[key];
    
    /* skip this touch and process the next */
    if (!touchInfo) return;
    
    UIBezierPath *path = touchInfo.path;
    
    /* Get the touch info we need */
    CGPoint point0 = touchInfo.point0;
    CGPoint point1 = touchInfo.point1;
    CGPoint point2 = touchInfo.point2;
    CGPoint point3 = touchInfo.point3;
    
    /* only calculate for control points if (touchInfo.point0  > -1) */
    if (point0.x < 0) return;
    touchInfo.hue += 0.005;
    if(touchInfo.hue > 1.0) touchInfo.hue = 0.0;
    
    /* Calculate for the control points */
    double x0 = (point0.x > -1) ? point0.x : point1.x; //after 4 touches we should have a back anchor point, if not, use the current anchor point
    double y0 = (point0.y > -1) ? point0.y : point1.y; //after 4 touches we should have a back anchor point, if not, use the current anchor point
    double x1 = point1.x;
    double y1 = point1.y;
    double x2 = point2.x;
    double y2 = point2.y;
    double x3 = point3.x;
    double y3 = point3.y;
    // Assume we need to calculate the control
    // points between (x1,y1) and (x2,y2).
    // Then x0,y0 - the previous vertex,
    //      x3,y3 - the next one.
    
    double xc1 = (x0 + x1) / 2.0;
    double yc1 = (y0 + y1) / 2.0;
    double xc2 = (x1 + x2) / 2.0;
    double yc2 = (y1 + y2) / 2.0;
    double xc3 = (x2 + x3) / 2.0;
    double yc3 = (y2 + y3) / 2.0;
    
    double len1 = sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0));
    double len2 = sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1));
    double len3 = sqrt((x3-x2) * (x3-x2) + (y3-y2) * (y3-y2));
    
    double k1 = len1 / (len1 + len2);
    double k2 = len2 / (len2 + len3);
    
    double xm1 = xc1 + (xc2 - xc1) * k1;
    double ym1 = yc1 + (yc2 - yc1) * k1;
    
    double xm2 = xc2 + (xc3 - xc2) * k2;
    double ym2 = yc2 + (yc3 - yc2) * k2;
    double smooth_value = 0.8;
    // Resulting control points. Here smooth_value is mentioned
    // above coefficient K whose value should be in range [0...1].
    float ctrl1_x = xm1 + (xc2 - xm1) * smooth_value + x1 - xm1;
    float ctrl1_y = ym1 + (yc2 - ym1) * smooth_value + y1 - ym1;
    
    float ctrl2_x = xm2 + (xc2 - xm2) * smooth_value + x2 - xm2;
    float ctrl2_y = ym2 + (yc2 - ym2) * smooth_value + y2 - ym2;
    
    //[path moveToPoint:point1];
    [path addCurveToPoint:point2 controlPoint1:CGPointMake(ctrl1_x, ctrl1_y) controlPoint2:CGPointMake(ctrl2_x, ctrl2_y)];
    
    CGFloat lineWidth = path.lineWidth;
    
    /* calculate our dirty rect */
    CGRect dirtyPoint1 = CGRectMake(point1.x - (lineWidth * 0.5), point1.y - (lineWidth * 0.5), lineWidth, lineWidth);
    CGRect dirtyPoint2 = CGRectMake(point2.x - (lineWidth * 0.5), point2.y - (lineWidth * 0.5), lineWidth, lineWidth);
    [self setNeedsDisplayInRect:CGRectUnion(dirtyPoint1, dirtyPoint2)];
}

- (void) drawRect:(CGRect)rect
{
    /* Performance metrics */
    uint64_t drawStart = mach_absolute_time();
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect clipRect = CGContextGetClipBoundingBox(ctx);
    clipRect = CGRectInset(clipRect, 0.5, 0.5);
    CGContextSetLineWidth(ctx, 1);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor redColor] CGColor]);
    CGContextStrokeRect(ctx, clipRect);
    
    
    UIColor *color = [UIColor colorWithRed:0.20392f green:0.19607f blue:0.61176f alpha:1.0f];
    
    [color set];
    for (UIBezierPath *path in _strokes)
        [path stroke];
    
    
    [[color colorWithAlphaComponent:0.5f] set];
    
    [_touchesInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        TouchInfo *touchInfo = (TouchInfo *)obj;
        if (touchInfo)
        {
            [touchInfo.path stroke];
        }
    }];
    
    
    /* using cache */
    
    /*
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGImageRef cacheImage = CGBitmapContextCreateImage(_cacheContext);
    CGContextDrawImage(context, self.bounds, cacheImage);
    CGImageRelease(cacheImage);
    */
    
    
    /* Performance metrics */
    uint64_t drawEnd = mach_absolute_time();
    [self recordPerformanceMetricsWithFrameStart:drawStart end:drawEnd];
}

#pragma mark -

- (void)recordPerformanceMetricsWithFrameStart:(uint64_t)start end:(uint64_t)end
{
    uint64_t        elapsed = end-start;
    uint64_t elapsedInMilli = elapsed/1000;
    NSLog(@"ms: %qu", elapsedInMilli);
}

@end
