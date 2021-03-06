//
//  ZoomViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZoomViewController.h"

@implementation ZoomViewController

@synthesize imageView = _imageView;

- (id)init {
  self = [super init];
  if (self) {
    self.wantsFullScreenLayout = YES;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  _containerView.delegate = nil;
  
  RELEASE_SAFELY(_imageView);
  RELEASE_SAFELY(_containerView);
}

- (void)dealloc {
  _containerView.delegate = nil;
  
  RELEASE_SAFELY(_imageView);
  RELEASE_SAFELY(_containerView);
  [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
//  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
//  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)loadView {
  
  _containerView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  _containerView.autoresizingMask = ~UIViewAutoresizingNone;
  _containerView.delegate = self;
  _containerView.maximumZoomScale = 3.0;
  _containerView.minimumZoomScale = 1.0;
  _containerView.bouncesZoom = YES;
  _containerView.backgroundColor = [UIColor clearColor];
  _containerView.showsVerticalScrollIndicator = NO;
  _containerView.showsHorizontalScrollIndicator = NO;
  
  _imageView = [[PSImageView alloc] initWithFrame:_containerView.bounds];
  _imageView.backgroundColor = [UIColor clearColor];
  _imageView.contentMode = UIViewContentModeScaleAspectFit;
  _imageView.userInteractionEnabled = YES;
  //    _imageView.alpha = 0.0;
  _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [_containerView addSubview:_imageView];
  
  self.view = _containerView;
  
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
  [_containerView addGestureRecognizer:tapGesture];
  [tapGesture release];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return _imageView;
}

//- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
//  CGFloat scaleFactor = [[UIScreen mainScreen] scale] * scale;
//  [_imageView setShouldScale:scaleFactor];
//}

- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)receivedRotate:(NSNotification *)notification {
  CGFloat windowWidth = [[UIApplication sharedApplication].keyWindow width];
  CGFloat windowHeight = [[UIApplication sharedApplication].keyWindow height];
  UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
  
  [UIView animateWithDuration:0.4
                   animations:^{
                     _containerView.zoomScale = 1.0;
                     if(interfaceOrientation == UIDeviceOrientationPortrait) {
                       self.view.transform = CGAffineTransformMakeRotation(RADIANS(0));
                       self.view.bounds = CGRectMake(0, 0, windowWidth, windowHeight);
                     }
                     else if(interfaceOrientation == UIDeviceOrientationLandscapeLeft) {
                       self.view.transform = CGAffineTransformMakeRotation(RADIANS(90));
                       self.view.bounds = CGRectMake(0, 0, windowHeight, windowWidth);
                     }
                     else if(interfaceOrientation == UIDeviceOrientationLandscapeRight) {
                       self.view.transform = CGAffineTransformMakeRotation(RADIANS(-90));
                       self.view.bounds = CGRectMake(0, 0, windowHeight, windowWidth);
                     }
                   }
                   completion:^(BOOL finished) {
                   }];
}

@end
