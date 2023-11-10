//
//  LKEditorTextView.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/7.
//

#import <UIKit/UIKit.h>
#import "LKEditorImagePicker.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, TextFormattingStyle) {
    TextFormattingStyleNormal = 10, ///< 普通文本
    TextFormattingStyleBold,        ///< 粗体
    TextFormattingStyleUnderline,   ///< 下划线
    TextFormattingStyleItatic,      ///< 斜体
    TextFormattingStyleColor,       ///< 文本颜色
    TextFormattingStyleFontSize,    ///< 字体大小
    TextFormattingStyleImage,       ///< 图片
};

@protocol LKRichTextEditorDelegate <NSObject>

@optional
/** 获取键盘工具栏支持的样式数组 返回 @TextFormattingStyle） 默认粗体、斜体、下划线*/
- (NSArray /**<TextFormattingStyle>*/*)supportToolBarItems;

@end

@interface LKEditorTextView : UITextView<LKEditorImagePickerProtocol>
// 图片选择器视图
@property (nonatomic, strong) id <LKEditorImagePickerProtocol> imagePicker;

@property (nonatomic, weak) id <LKRichTextEditorDelegate>toolBarDelegate;
/** 是否显示键盘工具栏 默认显示*/
@property (nonatomic, assign) BOOL showKeyboardTool;
/** textview显示高度最小值，当小于该值时，placeholder会默认居中显示，当大于该值时，placeholder默认离顶部距离为6*/
@property (nonatomic, assign) CGFloat minTextViewHeight;
/** 占位文字 */
@property (nonatomic, copy) NSString *placeholder;
/** 占位文字颜色 */
@property (nonatomic, strong) UIColor *placeholderColor;

    
/**
 * html转富文本
 * completion：设置完成回调
 */
- (void)setHtml:(NSString *)html completion:(void (^)(void))completion;
/**
 * 富文本转html
 */
- (void)getHtml:(void (^)(NSString *html))completion;

@end

NS_ASSUME_NONNULL_END
