//
//  OpenCV.m
//  OpenCVSample_iOS
//
//  Created by Hiroki Ishiura on 2015/08/12.
//  Copyright (c) 2015年 Hiroki Ishiura. All rights reserved.
//

// Put OpenCV include files at the top. Otherwise an error happens.
#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#import <Foundation/Foundation.h>
#import "OpenCV.h"

/// Converts an UIImage to Mat.
/// Orientation of UIImage will be lost.
static void UIImageToMat(UIImage *image, cv::Mat &mat) {
	assert(image.size.width > 0 && image.size.height);
	assert(image.CGImage != nil || image.CIImage != nil);

	// Create a pixel buffer.
	NSInteger width = image.size.width / 2;
	NSInteger height = image.size.height / 2;
	cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);

	// Draw all pixels to the buffer.
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (image.CGImage) {
		// Render with using Core Graphics.
		CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
		CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
		CGContextRelease(contextRef);
	} else {
		// Render with using Core Image.
		static CIContext* context = nil; // I do not like this declaration contains 'static'. But it is for performance.
		if (!context) {
			context = [CIContext contextWithOptions:@{ kCIContextUseSoftwareRenderer: @NO }];
		}
		CGRect bounds = CGRectMake(0, 0, width, height);
		[context render:image.CIImage toBitmap:mat8uc4.data rowBytes:mat8uc4.step bounds:bounds format:kCIFormatRGBA8 colorSpace:colorSpace];
	}
	CGColorSpaceRelease(colorSpace);

	// Adjust byte order of pixel.
	cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
	cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);
	
	mat = mat8uc3;
}

/// Converts an UIImage to Mat.
/// Orientation of UIImage will be lost.
static void UIImageToNMat(UIImage *image, std::vector<cv::Mat> &images, int n) {
    assert(image.size.width > 0 && image.size.height);
    assert(image.CGImage != nil || image.CIImage != nil);
    
    // Create a pixel buffer.
    NSInteger width = image.size.width / n;
    NSInteger height = image.size.height / n;
    cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
    
    // Draw all pixels to the buffer.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (image.CGImage) {
        // Render with using Core Graphics.
        CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
        CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
        CGContextRelease(contextRef);
    } else {
        // Render with using Core Image.
        static CIContext* context = nil; // I do not like this declaration contains 'static'. But it is for performance.
        if (!context) {
            context = [CIContext contextWithOptions:@{ kCIContextUseSoftwareRenderer: @NO }];
        }
        
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                CGRect bounds = CGRectMake(i * width, j * height, width, height);
                [context render:image.CIImage toBitmap:mat8uc4.data rowBytes:mat8uc4.step bounds:bounds format:kCIFormatRGBA8 colorSpace:colorSpace];
                
                cv::Mat mat = cv::Mat((int)width, (int)height, CV_8UC3);
                cv::cvtColor(mat8uc4, mat, CV_RGBA2BGR);
                
                images.push_back(mat);
            }
        }
    }
    CGColorSpaceRelease(colorSpace);
}


/// Converts a Mat to UIImage.
static UIImage *MatToUIImage(cv::Mat &mat) {
	
	// Create a pixel buffer.
	assert(mat.elemSize() == 1 || mat.elemSize() == 3);
	cv::Mat matrgb;
	if (mat.elemSize() == 1) {
		cv::cvtColor(mat, matrgb, CV_GRAY2RGB);
	} else if (mat.elemSize() == 3) {
		cv::cvtColor(mat, matrgb, CV_BGR2RGB);
	}
	
	// Change a image format.
	NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
	CGColorSpaceRef colorSpace;
	if (matrgb.elemSize() == 1) {
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return image;
}

/// Restore the orientation to image.
static UIImage *RestoreUIImageOrientation(UIImage *processed, UIImage *original) {
	if (processed.imageOrientation == original.imageOrientation) {
		return processed;
	}
	return [UIImage imageWithCGImage:processed.CGImage scale:1.0 orientation:original.imageOrientation];
}

#pragma mark -

@implementation OpenCV

+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image {
	cv::Mat bgrMat;
	UIImageToMat(image, bgrMat);
	cv::Mat grayMat;
	cv::cvtColor(bgrMat, grayMat, CV_BGR2GRAY);
	UIImage *grayImage = MatToUIImage(grayMat);
	return RestoreUIImageOrientation(grayImage, image);
}

+ (NSArray<UIImage *> *)cvtColorBGR2Array:(nonnull UIImage *)image splitCount:(int)count {
    std::vector<cv::Mat> images;
    UIImageToNMat(image, images, count);
    NSMutableArray *array = [NSMutableArray new];

    for (int i = 0; i < images.size(); i++) {
        UIImage *image = MatToUIImage(images.at(i));
        [array addObject:image];
    }

    return array;
}

+ (CGRect)calculateDiffFrom:(nonnull UIImage *)image to:(nonnull UIImage *)baseImage {
    cv::Mat imageMat;
    cv::Mat baseImageMat;
    
    UIImageToMat(image, imageMat);
    UIImageToMat(baseImage, baseImageMat);
    
    cv::Mat grayImageMat;
    cv::Mat grayBaseImageMat;

    cv::cvtColor(imageMat, grayImageMat, CV_BGR2GRAY);
    cv::cvtColor(baseImageMat, grayBaseImageMat, CV_BGR2GRAY);
    
    cv::Mat blurImageMat;
    cv::Mat blurBaseImageMat;
    
    cv::GaussianBlur(grayImageMat, blurImageMat, cv::Size(21,21), 0);
    cv::GaussianBlur(grayBaseImageMat, blurBaseImageMat, cv::Size(21,21), 0);
    
    cv::Mat frameDelta;
    cv::absdiff(blurImageMat, blurBaseImageMat, frameDelta);
    
    cv::Mat threshold;
    cv::threshold(frameDelta, threshold, 25, 255, cv::THRESH_BINARY);
    
    cv::Mat dilate;
    cv::dilate(threshold, dilate, NULL, cv::Point(-1,-1), 2);
    
    cv::Rect rect = cv::boundingRect(dilate);

    return CGRectMake(rect.x, rect.y, rect.width, rect.height);

}

/// Converts a full color image to grayscale image with using OpenCV.
+ (NSArray<NSNumber *> *_Nullable)calculateDiffArrayFrom:(nonnull UIImage *)image to:(nonnull UIImage *)baseImage  splitCount:(int)count {
    
    CGFloat width = image.size.width / count;
    CGFloat height = image.size.height / count;
    
    std::vector<cv::Mat> images;
    std::vector<cv::Mat> baseImages;
    UIImageToNMat(image, images, count);
    UIImageToNMat(baseImage, baseImages, count);
    
    NSMutableArray *result = [NSMutableArray new];
    
    for (int i = 0; i < count * count; i++) {
        cv::Mat imageMat = images.at(i);
        cv::Mat baseImageMat = baseImages.at(i);
        
        cv::Mat grayImageMat;
        cv::Mat grayBaseImageMat;
        
        cv::cvtColor(imageMat, grayImageMat, CV_BGR2GRAY);
        cv::cvtColor(baseImageMat, grayBaseImageMat, CV_BGR2GRAY);
        
        cv::Mat blurImageMat;
        cv::Mat blurBaseImageMat;
        
        cv::GaussianBlur(grayImageMat, blurImageMat, cv::Size(21,21), 0);
        cv::GaussianBlur(grayBaseImageMat, blurBaseImageMat, cv::Size(21,21), 0);
        
        cv::Mat frameDelta;
        cv::absdiff(blurImageMat, blurBaseImageMat, frameDelta);
        
        cv::Mat threshold;
        cv::threshold(frameDelta, threshold, 25, 255, cv::THRESH_BINARY);
        
        cv::Mat dilate;
        cv::dilate(threshold, dilate, NULL, cv::Point(-1,-1), 2);
        
        cv::Rect rect = cv::boundingRect(dilate);
        
        
        NSNumber *alpha = @(rect.width * rect.height / (width * height));
        [result addObject:alpha];
    }

    return result;
}


@end
