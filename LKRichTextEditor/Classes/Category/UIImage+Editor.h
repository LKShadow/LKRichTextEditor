//
//  UIImage+Editor.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Editor)

+ (UIImage *)resourceWithImageName:(NSString *)imageName;
/** 计算图片的MD5值*/
- (NSString *)calculateMD5ForImage;
@end

NS_ASSUME_NONNULL_END
