//
//  YHSelectImageProcess.h
//  YaoHe
//
//  Created by stonedong on 16/7/11.
//  Copyright © 2016年 stonedong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <RSKImageCropper/RSKImageCropper.h>
typedef NS_ENUM(NSInteger, YHSelectImageProcessType) {
    YHSelectImageProcessCamera,
    YHSelectImageProcessLibrary,
    YHSelectImageProcessAll
};
typedef void(^YHSelectedImageBlock)(UIImage* image);
typedef void(^YHSelectedImageUploadBlock)(NSString* url, NSError* error);
@interface YHSelectImageProcess : NSObject
@property (nonatomic, strong) YHSelectedImageBlock selectedBlock;
@property (nonatomic, strong) YHSelectedImageUploadBlock uploadedBlock;
@property (nonatomic, weak) UIViewController* rootViewController;
@property (nonatomic, strong) void (^CancelSelect)();
@property (nonatomic, assign) BOOL photoTweak;
@property (nonatomic, assign) YHSelectImageProcessType type;
@property (nonatomic, assign) RSKImageCropMode cropMode;
/**
 *  裁剪的宽高比，限定输入为0.5~2.0,只有当cropModel为Custom的时候生效
 */
@property (nonatomic, assign) CGFloat cropRatio;
- (void) start;
@end
