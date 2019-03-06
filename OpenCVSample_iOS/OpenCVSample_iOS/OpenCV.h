//
//  OpenCV.h
//  OpenCVSample_iOS
//
//  Created by Hiroki Ishiura on 2015/08/12.
//  Copyright (c) 2015年 Hiroki Ishiura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCV : NSObject

/// Converts a full color image to grayscale image with using OpenCV.
+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image;

/// Converts a full color image to grayscale image with using OpenCV.
+ (NSArray<UIImage *> *_Nullable)cvtColorBGR2Array:(nonnull UIImage *)image splitCount:(int)count;

/// Converts a full color image to grayscale image with using OpenCV.
+ (CGRect)calculateDiffFrom:(nonnull UIImage *)image to:(nonnull UIImage *)baseImage;

/// Converts a full color image to grayscale image with using OpenCV.
+ (NSArray<NSNumber *> *_Nullable)calculateDiffArrayFrom:(nonnull UIImage *)image to:(nonnull UIImage *)baseImage splitCount:(int)count ;

@end
