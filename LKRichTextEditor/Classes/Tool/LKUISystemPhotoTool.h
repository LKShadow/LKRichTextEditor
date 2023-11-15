//
//  LKUISystemPhotoTool.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/10.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN

#define COLOR_HEX(_rgbValue_) [UIColor colorWithRed:((float)((_rgbValue_ & 0xFF0000) >> 16))/255.0 green:((float)((_rgbValue_ & 0xFF00) >> 8))/255.0 blue:((float)(_rgbValue_ & 0xFF))/255.0 alpha:1.0]

@interface LKUISystemPhotoTool : NSObject
/** 获取controller*/
+ (UIViewController *)viewControllerFromView:(UIView *)view;
/** 弹框alert*/
+ (void)showAlertFromView:(UIView *)view withMessage:(NSString *)message;
/** 将秒 转化为hh:ss类型的字符串*/
+ (NSString *)formattedStringFromTimeInterval:(NSTimeInterval)timeInterval;
/** 计算图片大小*/
+ (NSString *)formattedSizeStringFromBytes:(NSUInteger)bytes;

/**
 * 获取图片信息
 * 返回 图像数据、UTI 和方向信息
 */
+ (void)fetchImageDataForAsset:(PHAsset *)asset completion:(void (^)(NSData *imageData, NSString *uti, UIImageOrientation orientation))completion;
@end

NS_ASSUME_NONNULL_END
