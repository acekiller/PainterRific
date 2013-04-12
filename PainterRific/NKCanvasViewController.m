//
//  NKCanvasViewController.m
//  PainterRific
//
//  Created by Nino Nhexie Kierulf on 10/4/13.
//  Copyright (c) 2013 Kierulf Pte Ltd. All rights reserved.
//

#import "NKCanvasViewController.h"

#define RESIZABLE(_VIEW_) [_VIEW_ setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth]

@interface NKCanvasViewController ()

@end

@implementation NKCanvasViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
