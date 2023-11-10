//
//  UIFont+TextFormat.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (TextFormat)

@property (nonatomic, readonly) BOOL isBold;
@property (nonatomic, readonly) BOOL isItatic;
@property (nonatomic, readonly) CGFloat fontSize;

- (UIFont *)copyWithItatic:(BOOL)isItatic;
- (UIFont *)copyWithBold:(BOOL)isBold;
- (UIFont *)copyWithFontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
