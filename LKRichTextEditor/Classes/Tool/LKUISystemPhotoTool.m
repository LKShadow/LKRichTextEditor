//
//  LKUISystemPhotoTool.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/10.
//

#import "LKUISystemPhotoTool.h"


@implementation LKUISystemPhotoTool
/** 获取controller*/
+ (UIViewController *)viewControllerFromView:(UIView *)view {
    UIResponder *responder = view;
    while (![responder isKindOfClass:[UIViewController class]] && responder != nil) {
        responder = [responder nextResponder];
    }
    
    return (UIViewController *)responder;
}
+ (void)showAlertFromView:(UIView *)view withMessage:(NSString *)message {
    UIViewController *viewController = [self viewControllerFromView:view];
    
    if (viewController) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    }
}

+ (NSString *)formattedStringFromTimeInterval:(NSTimeInterval)timeInterval {
    NSInteger hours = (NSInteger)(timeInterval / 3600);
    NSInteger minutes = (NSInteger)((fmod(timeInterval, 3600)) / 60);
    NSInteger seconds = (NSInteger)(fmod(timeInterval, 60));

    NSMutableArray *components = [NSMutableArray array];
    if (hours > 0) {
        [components addObject:[NSString stringWithFormat:@"%2ld", (long)hours]];
    }
    [components addObject:[NSString stringWithFormat:@"%02ld", (long)minutes]];

    [components addObject:[NSString stringWithFormat:@"%02ld", (long)seconds]];

    return [components componentsJoinedByString:@":"];
}

+ (NSString *)formattedSizeStringFromBytes:(NSUInteger)bytes {
    double fileSizeInKB = bytes / 1024.0;
    double fileSizeInMB = fileSizeInKB / 1024.0;

    NSString *sizeString;
    if (fileSizeInMB >= 1.0) {
        sizeString = [NSString stringWithFormat:@"%.2fMB", fileSizeInMB];
    } else {
        sizeString = [NSString stringWithFormat:@"%.2fKB", fileSizeInKB];
    }

    return sizeString;
}

+ (void)fetchImageDataForAsset:(PHAsset *)asset completion:(void (^)(NSData *imageData, NSString *uti, UIImageOrientation orientation))completion {
    PHImageManager *imageManager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [imageManager requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (completion) {
            completion(imageData,dataUTI,orientation);
        }
    }];
    
}

/// 图片 压缩
+ (UIImage *)compressionTheImaeg:(UIImage *)image maxMemory:(CGFloat)memory {
    NSData *imageData = UIImageJPEGRepresentation(image,1);
    CGFloat imageLength = [imageData length]/1000;
    if (imageLength < memory) {
        return image;
    }
    CGFloat compression = 1;
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        imageData = UIImageJPEGRepresentation(image, compression);
        imageLength = imageData.length/ 1000;
        if (imageLength < memory * 0.9) {
            min = compression;
        } else if (imageLength > memory) {
            max = compression;
        } else {
            break;
        }
    }
    UIImage *resultImage = [UIImage imageWithData:imageData];
    return resultImage;
}
@end
