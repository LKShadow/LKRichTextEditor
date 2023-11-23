//
//  LKEditorTextView.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/7.
//

#import "LKEditorTextView.h"
#import <Masonry/Masonry.h>
#import "UIFont+TextFormat.h"
#import "LKHTMLParser.h"
//#import "LKEditorToolBarView.h"
#import "LKEditorController.h"

@interface LKEditorTextView ()<LKEditorEditProtocol,UIScrollViewDelegate, UITextViewDelegate> {
    // 保存键盘弹出时的通知信息，用于获取键盘信息
    NSNotification          *_kbShowNotification;

}

@property (nonatomic, strong) LKEditorController *editorController;

/** 默认字体大小，当输入图片后，self.font会为空*/
@property (nonatomic, strong) UIFont *defaultFont;

@property (nonatomic, strong) UILabel *placeHolderLabel;
/** 设置占位文字的edge*/
@property (nonatomic, assign) UIEdgeInsets placeholderEdgeInsets;

/** 用于存储各类型的选中状态*/
@property (nonatomic, strong) NSMutableDictionary *textFormateStyleCache;
/** 记录最近的一次修改富文本的相关操作类型*/
@property (nonatomic, assign) TextFormattingStyle actionType;

/** 富文本&HTML转化工具*/
@property (nonatomic, strong) LKHTMLParser *parser;
@property (nonatomic, copy) NSString *originalHtml;
@end

@implementation LKEditorTextView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"self.text"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        [self initDefault];
        
        [self configPlaceHolder];
        // 添加相关监听通知
        [self addNotification];
        
    }
    return self;
}
// 初始化默认值
- (void)initDefault {
    self.delegate = self;
    self.inputAccessoryView = nil;
    // 设置默认颜色
    self.placeholderColor = [UIColor colorWithRed:128.0f/255.0f green:128.0f/255.0f blue:128.0f/255.0f alpha:1.0f];
    self.placeholder = @"请在此输入内容";
    self.font = [UIFont systemFontOfSize:16];
    self.minTextViewHeight = 40;
    self.placeholderEdgeInsets = UIEdgeInsetsMake(8, 6, 0, -4);
    self.contentOffset = CGPointMake(self.placeholderEdgeInsets.left, self.placeholderEdgeInsets.top);
    
    self.actionType = TextFormattingStyleNormal;
    
    self.textFormateStyleCache = [NSMutableDictionary dictionary];

    self.editorController = [[LKEditorController alloc] initWithEditor:self];
    
    self.parser = [[LKHTMLParser alloc] init];// 用于富文本与html转功能

}

- (void)addNotification {
    // 使用通知监听文字改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:self];
    // 添加通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

- (void)configPlaceHolder {
    [self addSubview:self.placeHolderLabel];
}

- (NSArray <NSNumber *>*)getToolBarItems {
    if (self.toolBarDataSource &&[self.toolBarDataSource respondsToSelector:@selector(supportToolBarItems)]) {
        NSArray *list = [self.toolBarDataSource supportToolBarItems];
        return list;
    }
    return @[@(TextFormattingStyleDismiss),@(TextFormattingStyleBold),@(TextFormattingStyleItatic),@(TextFormattingStyleUnderline)];
}
- (void)textDidChange:(NSNotification *)note {
    self.placeHolderLabel.hidden = self.text.length > 0 || self.attributedText.string.length > 0;

    [self updatePointFrameWithChanged];
    [self pointFocusChangedUpdateToolBarStyle];

}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 属性
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = self.font;
    attrs[NSForegroundColorAttributeName] = self.placeholderColor;
    // 计算占位符文字的大小
    CGSize placeholderSize = [_placeholder sizeWithAttributes:attrs];
    // 根据设置的 placeholderEdgeInsets 计算占位符的位置
    CGFloat pointY = self.placeholderEdgeInsets.top;
    CGFloat adjustedLeft = self.placeholderEdgeInsets.left;
    CGFloat adjustedWidth = self.frame.size.width - (fabs(self.placeholderEdgeInsets.right) + self.placeholderEdgeInsets.left);
    // 当高度小于 minTextViewHeight 时，垂直居中显示占位符
    if (self.frame.size.height < self.minTextViewHeight) {
        pointY = MAX((self.frame.size.height - placeholderSize.height) / 2, 0);
    }
    
    CGRect rect = CGRectMake(adjustedLeft, pointY, adjustedWidth, placeholderSize.height);
    self.placeHolderLabel.frame = rect;
}
#pragma mark - 修改输入的富文本
- (NSDictionary *)updateTypeAttribute {
    NSMutableDictionary *dict = self.typingAttributes.mutableCopy;
    id value = [self.textFormateStyleCache objectForKey:@(_actionType)];
    switch (_actionType) {
        case TextFormattingStyleBold:{
            UIFont *font = [self.defaultFont copy];
            [dict setObject:[font copyWithBold:[value boolValue]] forKey:NSFontAttributeName];
            break;
        }
        case TextFormattingStyleItatic: {
            UIFont *font = [self.defaultFont copy];
            [dict setObject:[font copyWithItatic:[value boolValue]] forKey:NSFontAttributeName];
            break;
        }
        case TextFormattingStyleUnderline: {
            if ([value boolValue]) {
                UIColor *color = [dict objectForKey:NSForegroundColorAttributeName] ?: [UIColor blackColor];
                [dict setObject:color forKey:NSUnderlineColorAttributeName];
                [dict setObject:@1 forKey:NSUnderlineStyleAttributeName];
            } else {
                [dict removeObjectForKey:NSUnderlineColorAttributeName];
                [dict removeObjectForKey:NSUnderlineStyleAttributeName];
            }
            break;
        }
        case TextFormattingStyleNormal:
        case TextFormattingStyleImage:
        default:{
            // 插入图片后，设置默认字体
            UIFont *font = [self.defaultFont copy];
            [dict setObject:font forKey:NSFontAttributeName];
            break;
        }
            break;
    }
    if (self.selectedRange.length <= 0) {
        self.typingAttributes = dict;
    }
    return dict;
}

#pragma mark - LKEditorEditProtocol
- (void)toolBarItemSelectedStateAction:(TextFormattingStyle)style withActionValue:(id)value {
    
    _actionType = style;
    [self.textFormateStyleCache setObject:value ?: @"" forKey:@(style)];// 缓存状态
    switch (style) {
        case TextFormattingStyleBold:{
            [self setBoldInRange];
        }
            break;
        case TextFormattingStyleItatic:
            [self setItaticInRange];
            break;
        case TextFormattingStyleUnderline:
            [self setUnderlineInRange];
            break;
        case TextFormattingStyleImage: {
            if ([value isKindOfClass:[NSArray class]]) {
                [self insertImagesInRange:value completion:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self updatePointFrameWithChanged];
                        [self resetEditorToolBarSelectedState];
                    });
                }];
            }
            [self.editorController.toolBarView updateToolBarItemSelectedState:TextFormattingStyleImage withActionValue:@(NO)];
            _actionType = TextFormattingStyleNormal;
            break;
        }
        default:
            break;
    }
    [self updateTypeAttribute];
}
- (void)updatePointFrameWithChanged {
    if (!self.editorController.showKeyboard) {
        return;
    }
    if (_kbShowNotification == nil) return;
    UIWindow *showWindow = [UIApplication sharedApplication].keyWindow;
    // 获取键盘的最终位置信息，包括键盘的高度和位置
    CGRect keyboardFrame = [[[_kbShowNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // 获取当前文本输入框中光标的位置
    UITextPosition *cursorPosition = [self selectedTextRange].start;
    CGRect caretRect = [self caretRectForPosition:cursorPosition];
    CGPoint careMaxPoint = CGPointMake(CGRectGetMaxX(caretRect), CGRectGetMaxY(caretRect));
    // 将光标最大坐标点转换为文本输入框父视图坐标系中
    CGPoint carePointOnSuperView = [self convertPoint:careMaxPoint toView:showWindow];
    
    // 将键盘的位置转换为文本输入框父视图坐标系中
//    CGRect keyboardInSuperView = [self convertRect:keyboardFrame toView:showWindow];
    CGPoint keyboardBottomInTextView = CGPointMake(CGRectGetMidX(keyboardFrame), CGRectGetMinY(keyboardFrame));
    // 计算光标最大坐标点与键盘底部在文本输入框父视图中的位置之间的垂直偏移量，额外减去60.0的偏移
    CGFloat offsetNeeded = carePointOnSuperView.y - keyboardBottomInTextView.y;
    // 只有在光标被遮挡时才移动offset
    if (offsetNeeded > 0) {
        // 移动文本输入框的内容偏移，确保光标不被键盘遮挡
        CGPoint contentOffset = self.contentOffset;
        contentOffset.y += offsetNeeded;
        [self setContentOffset:contentOffset animated:NO];
    }

}
#pragma mark - 监听键盘
- (void)keyboardWillShow:(NSNotification *)notification {
    _kbShowNotification = notification;
    [self updatePointFrameWithChanged];
}

// 键盘收回时的处理
- (void)keyboardWillHide:(NSNotification *)notification {
    // 恢复textView的contentOffset
    self.contentInset = UIEdgeInsetsZero;
    self.scrollIndicatorInsets = UIEdgeInsetsZero;
}
#pragma mark - 工具栏设置方法实现
- (void)modifyAttributedText:(void (^)(NSMutableAttributedString *attributedString))block {
    NSRange range = self.selectedRange;
    NSMutableAttributedString *attributedString = self.attributedText.mutableCopy;
    block(attributedString);
    self.attributedText = attributedString;
    self.selectedRange = range;
    [self scrollRangeToVisible:range];
}
/** 加粗*/
- (void)setBoldInRange {
    BOOL textFormateValue = [[self.textFormateStyleCache objectForKey:@(TextFormattingStyleBold)] boolValue];

    [self modifyAttributedText:^(NSMutableAttributedString *attributedString) {
        [attributedString enumerateAttribute:NSFontAttributeName inRange:self.selectedRange options:(NSAttributedStringEnumerationLongestEffectiveRangeNotRequired) usingBlock:^(id  _Nullable value, NSRange range0, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[UIFont class]]) {
                UIFont *font = value;
                [attributedString addAttribute:NSFontAttributeName value:[font copyWithBold:textFormateValue] range:range0];
            }
        }];
    }];
}
/** 斜体*/
- (void)setItaticInRange {
    BOOL textFormateValue = [[self.textFormateStyleCache objectForKey:@(TextFormattingStyleItatic)] boolValue];
    [self modifyAttributedText:^(NSMutableAttributedString *attributedString) {
        [attributedString enumerateAttribute:NSFontAttributeName inRange:self.selectedRange options:(NSAttributedStringEnumerationLongestEffectiveRangeNotRequired) usingBlock:^(id  _Nullable value, NSRange range0, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[UIFont class]]) {
                UIFont *font = value;
                [attributedString addAttribute:NSFontAttributeName value:[font copyWithItatic:textFormateValue] range:range0];
            }
        }];
    }];
}
/** 下划线*/
- (void)setUnderlineInRange {
    BOOL textFormateValue = [[self.textFormateStyleCache objectForKey:@(TextFormattingStyleUnderline)] boolValue];
    [self modifyAttributedText:^(NSMutableAttributedString *attributedString) {
        if (textFormateValue == NO) {
            [attributedString removeAttribute:NSUnderlineStyleAttributeName range:self.selectedRange];
            [attributedString removeAttribute:NSUnderlineColorAttributeName range:self.selectedRange];
            self.attributedText = attributedString.copy;
            return;
        }
        
        [attributedString enumerateAttribute:NSForegroundColorAttributeName inRange:self.selectedRange options:(NSAttributedStringEnumerationLongestEffectiveRangeNotRequired) usingBlock:^(id  _Nullable value, NSRange range0, BOOL * _Nonnull stop) {
            
            if ([value isKindOfClass:[UIColor class]]) {
                UIColor *color = value;
                [attributedString addAttribute:NSUnderlineColorAttributeName value:color range:range0];
                [attributedString addAttribute:NSUnderlineStyleAttributeName value:@1 range:range0];
            }
        }];
    }];
}
/** 字体大小*/
- (void)setFontSizeInRange {
    CGFloat textFormateValue = [[self.textFormateStyleCache objectForKey:@(TextFormattingStyleFontSize)] floatValue];
    [self modifyAttributedText:^(NSMutableAttributedString *attributedString) {
        [attributedString enumerateAttribute:NSFontAttributeName inRange:self.selectedRange options:(NSAttributedStringEnumerationLongestEffectiveRangeNotRequired) usingBlock:^(id  _Nullable value, NSRange range0, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[UIFont class]]) {
                UIFont *font = value;
                [attributedString addAttribute:NSFontAttributeName value:[font copyWithFontSize:textFormateValue] range:range0];
            }
        }];
    }];
}
/** 颜色*/
- (void)setTextColorInRange {
    UIColor *textFormateValue = [self.textFormateStyleCache objectForKey:@(TextFormattingStyleColor)];
    [self modifyAttributedText:^(NSMutableAttributedString *attributedString) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:textFormateValue range:self.selectedRange];
    }];
}
/** 图片*/
- (void)insertImagesInRange:(NSArray<UIImage *> *)images {
    if (images.count == 0) {
        [self becomeFirstResponder];
        return;
    }
    [self insertImagesInRange:images completion:^{
        
    }];
}

- (void)insertImagesInRange:(NSArray<UIImage *> *)images completion:(void(^)(void))completion {
    if (images.count == 0) {
        [self becomeFirstResponder];
        if (completion) {
            completion();
        }
        return;
    }

    CGFloat width = self.frame.size.width - self.textContainer.lineFragmentPadding * 2;

    NSMutableAttributedString *mAttributedString = self.attributedText.mutableCopy;
    NSInteger lastImageLocation = NSNotFound; // 记录最后一个图片的位置

    for (UIImage *image in images) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.bounds = CGRectMake(0, 0, width, width * image.size.height / image.size.width);
        attachment.image = image;

        NSMutableAttributedString *attachmentString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];

        [attachmentString addAttributes:[self updateTypeAttribute] range:NSMakeRange(0, attachmentString.length)];

        lastImageLocation = lastImageLocation == NSNotFound ? NSMaxRange(self.selectedRange) : lastImageLocation; // 更新最后一个图片的位置
        [mAttributedString insertAttributedString:attachmentString atIndex:lastImageLocation];
        
        // 在每张图片后插入换行符
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n"];
        [mAttributedString insertAttributedString:newLine atIndex:lastImageLocation + 1];
        
        // 更新最后一个图片的位置
        lastImageLocation += 2;
    }
    if (completion) {
        completion();
    }
    // 计算新的selectedRange，将光标移动到插入最后一张图片的下一行
    NSInteger newSelectedLocation = lastImageLocation;
    self.selectedRange = NSMakeRange(newSelectedLocation, 0);

    // 更新attributedText
    self.attributedText = mAttributedString.copy;

    if (![self isFirstResponder]) {
        [self resignFirstResponder];
        [self becomeFirstResponder];
    }
}
- (void)replaceText:(NSString *)text andInsertImage:(UIImage *)image  withImageSize:(CGSize)imgSize {
    if (text == nil || image == nil) {
        return;
    }
    if (CGSizeEqualToSize(imgSize, CGSizeZero)) {
        imgSize = image.size;
    }
    NSMutableAttributedString *mAttributedString = self.attributedText.mutableCopy;
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.bounds = CGRectMake(2, -4, imgSize.width, imgSize.height);
    attachment.image = image;
    NSMutableAttributedString *attachmentString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [attachmentString addAttributes:[self updateTypeAttribute] range:NSMakeRange(0, attachmentString.length)];
    NSRange replaceRange = [mAttributedString.string rangeOfString:text];
    [mAttributedString replaceCharactersInRange:replaceRange withAttributedString:attachmentString];
//    [mAttributedString insertAttributedString:attachmentString atIndex:self.selectedRange.location];
    
    
    self.selectedRange = NSMakeRange(self.selectedRange.location + 1, 0);
    // 更新attributedText
    self.attributedText = mAttributedString.copy;
    [self pointFocusChangedUpdateToolBarStyle];
}

#pragma mark - 更新toolbar状态
- (void)pointFocusChangedUpdateToolBarStyle {
    if ([self isFirstResponder] == NO) return;
    NSDictionary *attrs = self.typingAttributes;
    UIFont *font = attrs[NSFontAttributeName];
    BOOL isUnderLine = [attrs.allKeys containsObject:NSUnderlineStyleAttributeName];
    LKEditorToolBarView *barView = (LKEditorToolBarView *)self.editorController.toolBarView;
    [barView updateToolBarItemSelectedState:TextFormattingStyleBold withActionValue:@(font.isBold)];
    [barView updateToolBarItemSelectedState:TextFormattingStyleItatic withActionValue:@(font.isItatic)];
    [barView updateToolBarItemSelectedState:TextFormattingStyleUnderline withActionValue:@(isUnderLine)];
    
}
// 重置状态栏的按钮选择状态
- (void)resetEditorToolBarSelectedState {
    LKEditorToolBarView *barView = (LKEditorToolBarView *)self.editorController.toolBarView;
    [barView updateToolBarItemSelectedState:TextFormattingStyleBold withActionValue:@(NO)];
    [barView updateToolBarItemSelectedState:TextFormattingStyleItatic withActionValue:@(NO)];
    [barView updateToolBarItemSelectedState:TextFormattingStyleUnderline withActionValue:@(NO)];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    static UIEvent *e = nil;
    if (e != nil && e == event) {
        e = nil;
        return [super hitTest:point withEvent:event];
    }
    e = event;
    if (event.type == UIEventTypeTouches) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self pointFocusChangedUpdateToolBarStyle];
        });
    }
    return [super hitTest:point withEvent:event];
}
#pragma mark - 富文本 <<--->> HTML
- (void)setHtml:(NSString *)html completion:(void (^)(void))completion {
    self.originalHtml = html;
    if (html.length == 0) {
        self.attributedText = nil;
        return;
    }
    CGFloat imageWidth = self.frame.size.width - self.textContainer.lineFragmentPadding * 2;
    [self.parser attributedWithHtml:html imageWidth:imageWidth completion:^(NSAttributedString *attributedText) {
        self.attributedText = attributedText;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    }];
}

- (void)getHtml:(void (^)(NSString * _Nonnull))completion {
    [self.parser htmlWithAttributed:self.attributedText orignalHtml:self.originalHtml completion:completion];
}

#pragma mark - setter

- (void)setImageUploader:(id<LKEditorUploadImageProtocol>)uploader {
    self.parser.imageUpLoader = uploader;
}
- (void)setToolBarDataSource:(id<LKEditorToolBarDataSourceDelegate>)toolBarDataSource {
    _toolBarDataSource = toolBarDataSource;
    [self.editorController.toolBarView updateToolbarItems:[self getToolBarItems]];
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = [placeholder copy];
    _placeHolderLabel.text = placeholder;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    _placeHolderLabel.textColor = placeholderColor;
}
- (void)setFont:(UIFont *)font {
    [super setFont:font];
    _placeHolderLabel.font = font;
    self.defaultFont = font;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    self.placeHolderLabel.hidden = text.length > 0;
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    self.placeHolderLabel.hidden = attributedText.string.length > 0;
    [self setNeedsDisplay];
}
- (UIFont *)defaultFont {
    if (self.font == nil) {
        return [UIFont systemFontOfSize:16];
    }
    return self.font;
}
#pragma mark - UI
- (UILabel *)placeHolderLabel {
    if (!_placeHolderLabel) {
        _placeHolderLabel = [[UILabel alloc] init];
        _placeHolderLabel.textColor = [UIColor lightGrayColor];
        _placeHolderLabel.textAlignment = NSTextAlignmentLeft;
        _placeHolderLabel.font = self.font;
        _placeHolderLabel.text = @"请在此输入内容";
    }
    return _placeHolderLabel;
}
@end
