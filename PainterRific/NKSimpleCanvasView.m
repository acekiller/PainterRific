//
//  NKSimpleCanvas.m
//  PainterRific
//
//  Created by Nino Nhexie Kierulf on 10/4/13.
//  Copyright (c) 2013 Kierulf Pte Ltd. All rights reserved.
//

#import "NKSimpleCanvasView.h"

@interface NKSimpleCanvasView()
@property (assign, nonatomic) void *cacheBitmap;
@property (assign, nonatomic) CGContextRef cacheContext;

@property (assign, nonatomic) CGPoint startPoint;
@property (strong, nonatomic) NSMutableArray *drawnPoints;
@property (strong, nonatomic) UIColor *color;

@end

@implementation NKSimpleCanvasView

#pragma mark Initialization

- (void)commonInit
{
    /* We want to draw with multiple fingers, that would be fun */
    [self setMultipleTouchEnabled:NO];
    
    _drawnPoints = [NSMutableArray array];
    _color = [UIColor blackColor];
    
    /* Initialize collection stores */
    //[self setStrokes:[NSMutableArray array]];
    //[self setTouchPaths:[NSMutableDictionary dictionary]];
}

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect]))
    {
        [self commonInit];
        [self initContext:aRect.size];
    }
    return self;
}

- (BOOL) initContext:(CGSize)size
{
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

#pragma mark Touch Events

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event
{
    UIView *thisView = self;
    
    CGPoint thisPoint = [[touches anyObject] locationInView:thisView];
    
	[_drawnPoints addObject:[NSValue valueWithCGPoint:thisPoint]];
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event
{
    UIView *thisView = self;
    
    CGPoint lastPoint = [[touches anyObject] previousLocationInView:thisView];
    CGPoint thisPoint = [[touches anyObject] locationInView:thisView];
    
    [_drawnPoints addObject:[NSValue valueWithCGPoint:thisPoint]];
    
    CGPoint firstPoint = [_drawnPoints[0] CGPointValue];
    if (CGPointEqualToPoint(lastPoint, firstPoint))
    {
        
    }
    
    CGContextSetStrokeColorWithColor(_cacheContext, [_color CGColor]);
    CGContextSetLineCap(_cacheContext, kCGLineCapRound);
    CGContextSetLineWidth(_cacheContext, 15);
    
    NSInteger pointsCount = [_drawnPoints count];
    NSInteger currentIndex = pointsCount - 1; // zero based
    
    NSInteger indexMinus3 = (currentIndex - 3);
    NSInteger indexMinus2 = (currentIndex - 2);
    NSInteger indexMinus1 = (currentIndex - 1);
    NSInteger indexMinus0 = (currentIndex - 0);
    
    CGPoint defaultPoint = CGPointMake(-1, -1);
    
    CGPoint point0 = indexMinus3 <= 0 ? defaultPoint : [_drawnPoints[indexMinus3] CGPointValue];
    CGPoint point1 = indexMinus2 <= 0 ? defaultPoint : [_drawnPoints[indexMinus2] CGPointValue];
    CGPoint point2 = indexMinus1 <= 0 ? defaultPoint : [_drawnPoints[indexMinus1] CGPointValue];
    CGPoint point3 = indexMinus0 <= 0 ? defaultPoint : [_drawnPoints[indexMinus0] CGPointValue];
    
	if(point1.x > -1)
    {
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
        
        CGContextMoveToPoint(_cacheContext, point1.x, point1.y);
        CGContextAddCurveToPoint(_cacheContext, ctrl1_x, ctrl1_y, ctrl2_x, ctrl2_y, point2.x, point2.y);
        CGContextStrokePath(_cacheContext);
        
        CGRect dirtyPoint1 = CGRectMake(point1.x-10, point1.y-10, 20, 20);
        CGRect dirtyPoint2 = CGRectMake(point2.x-10, point2.y-10, 20, 20);
        [self setNeedsDisplayInRect:CGRectUnion(dirtyPoint1, dirtyPoint2)];
    }
}




#pragma mark Custom Drawing

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGImageRef cacheImage = CGBitmapContextCreateImage(_cacheContext);
    CGContextDrawImage(context, self.bounds, cacheImage);
    CGImageRelease(cacheImage);
}

@end
