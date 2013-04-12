//
//  NKCanvasLayer.h
//  PainterRific
//
//  Created by Nino Nhexie Kierulf on 11/4/13.
//  Copyright (c) 2013 Kierulf Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKCanvasLayer : CALayer


- (void)beginPathAtPoint:(CGPoint)point;
- (void)addNextPoint:(CGPoint)point;
- (void)endPath;

@end
