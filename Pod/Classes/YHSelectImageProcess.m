//
//  YHSelectImageProcess.m
//  YaoHe
//
//  Created by stonedong on 16/7/11.
//  Copyright © 2016年 stonedong. All rights reserved.
//

#import "YHSelectImageProcess.h"
#import <DZProgrameDefines/DZProgrameDefines.h>
#import <UIKit/UIKit.h>
#import "YHUploadManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <RSKImageCropper/RSKImageCropper.h>
#import <DZFixImage/DZFixImage.h>

@interface YHSelectImageProcess () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource>
@property (nonatomic, strong) NSString* key;
@end

@implementation YHSelectImageProcess

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _type = YHSelectImageProcessAll;
    _cropMode = RSKImageCropModeSquare;
    return self;
}

INIT_DZ_EXTERN_STRING(kDZIMGFromLocal, 相册)
INIT_DZ_EXTERN_STRING(kDZIMGFromCamera,拍照 )
- (UIViewController*) rootViewController
{
    if (_rootViewController) {
        return _rootViewController;
    }
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}
- (void) start
{
    if (self.type == YHSelectImageProcessCamera) {
        UIImagePickerController* pickerVC = [[UIImagePickerController alloc]init];
        pickerVC.delegate = self;
        pickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
        UIViewController* vc = self.rootViewController;
        [vc presentViewController:pickerVC animated:YES completion:^{
            
        }];
    } else if (self.type == YHSelectImageProcessLibrary) {
        UIImagePickerController* pickerVC = [[UIImagePickerController alloc]init];
        pickerVC.delegate = self;
        pickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        UIViewController* vc = self.rootViewController;
        [vc presentViewController:pickerVC animated:YES completion:^{
            
        }];
    } else {
        [self takePicture];
    }
}

- (void) setCropRatio:(CGFloat)cropRatio{
    if (cropRatio < 0.5) {
        _cropRatio = 0.5;
    } else if (cropRatio > 2.0) {
        _cropRatio = 2.0;
    } else {
        _cropRatio = cropRatio;
    }
}

- (void) takePicture
{
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"选择照片" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:kDZIMGFromLocal,kDZIMGFromCamera, nil];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString* title = [actionSheet buttonTitleAtIndex:buttonIndex];
    UIImagePickerController* pickerVC = [[UIImagePickerController alloc]init];
    pickerVC.delegate = self;
    if ([title isEqualToString:kDZIMGFromCamera]) {
        pickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else if ([title isEqualToString:kDZIMGFromLocal]) {
        pickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    else {
        if (self.uploadedBlock) {
            NSError* error = [NSError errorWithDomain:@"com.yaohe.select.image" code:11 userInfo:@{NSLocalizedDescriptionKey:@"用户取消"}];
            self.uploadedBlock(nil, error);
        }
        return;
    }
   
    UIViewController* vc = self.rootViewController;
    [vc presentViewController:pickerVC animated:YES completion:^{
        
    }];
}


- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.CancelSelect) {
        self.CancelSelect();
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}



- (void) uploadImage:(UIImage *)image
{
    self.key = [NSUUID UUID].UUIDString;
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [[YHUploadManager shareManager] uploadImage:image withKey:self.key process:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        [SVProgressHUD showProgress:(float)totalBytesSent/totalBytesExpectedToSend];
    } finish:^(NSError * error, NSString * url) {
        if (url) {
            [weakSelf didUploadedImage:image withURL:url];
            [SVProgressHUD dismiss];
        } else
        {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }
        if (weakSelf.uploadedBlock) {
            weakSelf.uploadedBlock(url, error);
        }
    }];
}

- (void) didUploadedImage:(UIImage*)image withURL:(NSString*)url
{
    if (!url) {
        return;
    }
}


// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{

    if (self.CancelSelect) {
        self.CancelSelect();
    }
    [controller.navigationController dismissViewControllerAnimated:YES completion:^{
            [UIApplication sharedApplication].statusBarHidden = NO;
    }];
        [UIApplication sharedApplication].statusBarHidden = NO;
}

// The original image has been cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
{

    if (self.selectedBlock) {
        self.selectedBlock(croppedImage);
    }
    
    [self uploadImage:croppedImage];
    [controller.navigationController dismissViewControllerAnimated:YES completion:^{
            [UIApplication sharedApplication].statusBarHidden = NO;
    }];
       [UIApplication sharedApplication].statusBarHidden = NO;
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{

    if (self.selectedBlock) {
        self.selectedBlock(croppedImage);
    }
    
    [self uploadImage:croppedImage];
    [controller.navigationController dismissViewControllerAnimated:YES completion:^{
            [UIApplication sharedApplication].statusBarHidden = NO;
    }];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

// The original image will be cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                  willCropImage:(UIImage *)originalImage
{
    // Use when `applyMaskToCroppedImage` set to YES.
    [SVProgressHUD show];
}
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage* image = info[UIImagePickerControllerOriginalImage];
    image = [image fixAppearance];
        
    if (self.photoTweak) {
        RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:image];
        imageCropVC.delegate = self;
        imageCropVC.cropMode = self.cropMode;
        imageCropVC.dataSource = self;
        [picker pushViewController:imageCropVC animated:YES];
    } else {
        [self uploadImage:image];
        if (self.selectedBlock) {
            self.selectedBlock(image);
        }
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (CGRect) imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGSize maskSize;
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    width = width - 60;
    CGFloat height = width * self.cropRatio;
    maskSize.width = width;
    maskSize.height = height;
  
    
    CGFloat viewWidth = CGRectGetWidth(controller.view.frame);
    CGFloat viewHeight = CGRectGetHeight(controller.view.frame);
    
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}
- (UIBezierPath*) imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller
{
    CGRect rect = controller.maskRect;
    return [UIBezierPath bezierPathWithRect:rect];
}

- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    return controller.maskRect;
}
@end
