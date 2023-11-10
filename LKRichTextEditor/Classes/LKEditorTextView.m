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
#import "LKEditorToolBarView.h"
#import "LKEditorImagePicker.h"

@interface LKEditorTextView ()<LKEditorToolBarViewDelegate>
/** 工具栏视图设置，默认使用 LKEditorToolBarView */
@property (nonatomic, strong) LKEditorToolBarView *toolBarView;

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
        // 是否显示键盘工具栏
        self.showKeyboardTool = YES;
        // 设置默认颜色
        self.placeholderColor = [UIColor colorWithRed:128.0f/255.0f green:128.0f/255.0f blue:128.0f/255.0f alpha:1.0f];
        self.placeholder = @"请在此输入内容";
        self.font = [UIFont systemFontOfSize:16];
        self.minTextViewHeight = 40;
        self.placeholderEdgeInsets = UIEdgeInsetsMake(6, 6, 0, -4);
        self.contentOffset = CGPointMake(self.placeholderEdgeInsets.left, self.placeholderEdgeInsets.top);
        self.textFormateStyleCache = [NSMutableDictionary dictionary];
        
        self.parser = [[LKHTMLParser alloc] init];
        [self configPlaceHolder];
        
        // 配置默认toolview
        [self configKeyboardToolBarView];
        // 添加相关监听通知
        [self addNotification];
        
    }
    return self;
}

- (void)addNotification {
    // 使用通知监听文字改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:self];
    //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChangeNotification:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)configPlaceHolder {
    [self addSubview:self.placeHolderLabel];
}

- (void)configKeyboardToolBarView {
    if (!self.showKeyboardTool) {
        self.inputAccessoryView = nil;
        return;
    };
    if (self.toolBarView) {
        self.inputAccessoryView = self.toolBarView;
    } else {
        LKEditorToolBarView *toolbarView = [[LKEditorToolBarView alloc] init];
        toolbarView.delegate = self;
        self.inputAccessoryView = toolbarView;
        self.toolBarView = toolbarView;
    }
    [self.toolBarView updateToolbarItems:[self getToolBarItems]];
    [self pointFocusChangedUpdateToolBarStyle];
}

- (NSArray *)getToolBarItems {
    if (self.toolBarDelegate &&[self.toolBarDelegate respondsToSelector:@selector(supportToolBarItems)]) {
        NSArray *list = [self.toolBarDelegate supportToolBarItems];
        return list;
    }
    return @[@(TextFormattingStyleBold),@(TextFormattingStyleItatic),@(TextFormattingStyleUnderline)];
}
- (void)textDidChange:(NSNotification *)note {
    self.placeHolderLabel.hidden = self.text.length > 0 || self.attributedText.string.length > 0;
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
        pointY = MAX((self.frame.size.height - placeholderSize.height) / 2 - 2, 0);
    }
    
    CGRect rect = CGRectMake(adjustedLeft, pointY, adjustedWidth, placeholderSize.height);
    self.placeHolderLabel.frame = rect;
}


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
#pragma mark - 修改输入的富文本
- (NSDictionary *)updateTypeAttribute {
    NSMutableDictionary *dict = self.typingAttributes.mutableCopy;
    id value = [self.textFormateStyleCache objectForKey:@(_actionType)];
    switch (_actionType) {
        case TextFormattingStyleBold:{
            UIFont *font = [dict objectForKey:NSFontAttributeName] ?: [UIFont systemFontOfSize:15];
            [dict setObject:[font copyWithBold:[value boolValue]] forKey:NSFontAttributeName];
            break;
        }
        case TextFormattingStyleItatic: {
            UIFont *font = [dict objectForKey:NSFontAttributeName] ?: [UIFont systemFontOfSize:15];;
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
            
        default:
            break;
    }
    if (self.selectedRange.length <= 0) {
        self.typingAttributes = dict;
    }
    return dict;
}

#pragma mark - LKEditorToolBarViewDelegate 工具栏点击事件
- (void)toolBarClickTextFormattingStyle:(TextFormattingStyle)style withActionValue:(id)value {
    _actionType = style;
    [self.textFormateStyleCache setObject:value forKey:@(style)];// 缓存状态
    
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
            if ([value isKindOfClass:[UIImage class]]) {
                [self insertImageInRange:(UIImage *)value];
            }
        }
        default:
            break;
    }
    [self updateTypeAttribute];
            
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
- (void)insertImageInRange:(UIImage *)image {
    if (image == nil) {
        [self becomeFirstResponder];
        return;
    }

    CGFloat width = self.frame.size.width-self.textContainer.lineFragmentPadding*2;
    
    NSMutableAttributedString *mAttributedString = self.attributedText.mutableCopy;
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.bounds = CGRectMake(0, 0, width, width * image.size.height / image.size.width);
    attachment.image = image;
    
    NSMutableAttributedString *attachmentString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    
    [attachmentString addAttributes:[self updateTypeAttribute] range:NSMakeRange(0, attachmentString.length)];
    
    [mAttributedString insertAttributedString:attachmentString atIndex:NSMaxRange(self.selectedRange)];
    
    //更新attributedText
    NSInteger location = NSMaxRange(self.selectedRange) + 1;
    self.attributedText = mAttributedString.copy;
    
    //恢复焦点
    self.selectedRange = NSMakeRange(location, 0);
    [self becomeFirstResponder];
}
#pragma mark - 更新toolbar状态
- (void)pointFocusChangedUpdateToolBarStyle {
    if ([self isFirstResponder] == NO) return;
    NSDictionary *attrs = self.typingAttributes;
    UIFont *font = attrs[NSFontAttributeName];
    BOOL isUnderLine = [attrs.allKeys containsObject:NSUnderlineStyleAttributeName];
    if ([self.toolBarView isKindOfClass:[LKEditorToolBarView class]]) {
        LKEditorToolBarView *barView = (LKEditorToolBarView *)self.toolBarView;
        [barView updateToolBarItemSelectedState:TextFormattingStyleBold withActionValue:@(font.isBold)];
        [barView updateToolBarItemSelectedState:TextFormattingStyleItatic withActionValue:@(font.isItatic)];
        [barView updateToolBarItemSelectedState:TextFormattingStyleUnderline withActionValue:@(isUnderLine)];
    }
    
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

- (void)setShowKeyboardTool:(BOOL)showKeyboardTool {
    _showKeyboardTool = showKeyboardTool;
    [self configKeyboardToolBarView];
}

- (void)setToolBarDelegate:(id<LKRichTextEditorDelegate>)toolBarDelegate {
    _toolBarDelegate = toolBarDelegate;
    [self configKeyboardToolBarView];
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

@end
