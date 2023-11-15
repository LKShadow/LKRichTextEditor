//
//  LKEditorTextView.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/7.
//

#import <UIKit/UIKit.h>
@class LKEditorController;
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
@protocol LKEditorEditProtocol <NSObject>
/**
 * 更新状态来对应的选中状态状态
 *  @Param style 点击按钮对应的事件类型
 *  @Param value 按钮事件后对应的选择的状态，或值 ，比如选择后的图片、选择的字体大小值
*/
- (void)toolBarItemSelectedStateAction:(TextFormattingStyle)style withActionValue:(id _Nullable)value;


@end

@protocol LKEditorImagePickerProtocol
/** 图片选择协议*/
- (void)showWithTextEditor:(UITextView *)textView completion:(void (^) (UIImage *pickerImage))completion;

@end


@protocol LKEditorToolBarDataSourceDelegate <NSObject>

@optional
/** 获取键盘工具栏支持的样式数组 返回 @TextFormattingStyle） 默认粗体、斜体、下划线*/
- (NSArray /**<TextFormattingStyle>*/<NSNumber *>*)supportToolBarItems;

@end

@interface LKEditorTextView : UITextView

@property (nonatomic, weak) id <LKEditorToolBarDataSourceDelegate>toolBarDataSource;
/** textview显示高度最小值，当小于该值时，placeholder会默认居中显示，当大于该值时，placeholder默认离顶部距离为6*/
@property (nonatomic, assign) CGFloat minTextViewHeight;
/** 占位文字 */
@property (nonatomic, copy) NSString *placeholder;
/** 占位文字颜色 */
@property (nonatomic, strong) UIColor *placeholderColor;
/** 工具栏相关控制管理器,只有设置datasource代理，才可以获取该值*/
@property (nonatomic, strong, readonly) LKEditorController *editorController;

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
