//
//  NKCanvasView.m
//  PainterRific
//
//  Created by Nino Nhexie Kierulf on 10/4/13.
//  Copyright (c) 2013 Kierulf Pte Ltd. All rights reserved.
//

#import "NKCanvasView.h"
#import "NKCanvasLayer.h"

@interface NKCanvasView()

@property (strong) NKCanvasLayer *canvasLayer;

@end

@implementation NKCanvasView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    /* This is assuming that frame has been set */
    CGRect frame = self.frame;
    
    NKCanvasLayer *canvasLayer = [NKCanvasLayer new];
    [canvasLayer setFrame:frame];
    [self setCanvasLayer:canvasLayer];
    
    [self.layer addSublayer:canvasLayer];
}

#pragma mark Touch Events
- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event
{
    UIView *thisView = self;
    CGPoint thisPoint = [[touches anyObject] locationInView:thisView];
    
    [self.canvasLayer beginPathAtPoint:thisPoint];
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event
{
    UIView *thisView = self;
    CGPoint thisPoint = [[touches anyObject] locationInView:thisView];
    
    [self.canvasLayer addNextPoint:thisPoint];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIView *thisView = self;
    CGPoint thisPoint = [[touches anyObject] locationInView:thisView];
	
    [self.canvasLayer addNextPoint:thisPoint];
    [self.canvasLayer endPath];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
