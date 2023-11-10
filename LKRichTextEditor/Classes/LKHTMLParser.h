//
//  LKHTMLParser.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/9.
//  数据转换过程：(双向) NSAttributedString <-> HTML

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKHTMLParser : NSObject
/** 富文本转html*/
- (void)htmlWithAttributed:(NSAttributedString *)attributed
                        orignalHtml:(NSString *__nullable)orignalHtml
                   completion:(void (^)(NSString *html))completion;
/** html字符串转富文本*/
- (void)attributedWithHtml:(NSString *)html
                    imageWidth:(CGFloat)imageWidth
                completion:(void (^)(NSAttributedString *attributedText))completion;

@end

NS_ASSUME_NONNULL_END
