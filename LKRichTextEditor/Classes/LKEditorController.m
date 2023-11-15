//
//  LKEditorManager.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/10.
//

#import "LKEditorController.h"
#import <Masonry/Masonry.h>
#import <LKRichTextEditor/LKEditorImagePicker.h>
/// 工具栏的高度，宽度默认屏幕宽度
static CGFloat const Editor_ToolBar_Height = 40;
/// 工具栏中图片选择器的高度， 宽度默认屏幕宽度
static CGFloat const Editor_ImageSelected_Height = 200 + 50;

@interface LKEditorController ()<LKEditorToolBarViewDelegate, UITextViewDelegate>{
    CGFloat editorInsetsBottom;
    CGFloat keyboardHeight;
    CGFloat bottomSafeAreaHeight;
}
@property (nonatomic, weak) UITextView <LKEditorEditProtocol>*editor;

@property (nonatomic, strong) LKEditorImagePicker <LKEditorImagePickerProtocol> *imagePicker;
/** 工具栏视图设置，默认使用 LKEditorToolBarView */
@property (nonatomic, strong) LKEditorToolBarView *toolBarView;
/** 记录最近的一次修改富文本的相关操作类型*/
@property (nonatomic, assign) TextFormattingStyle actionType;
/** 记录keyboard的显示状态*/
@property (nonatomic, assign) BOOL showKeyboard;


@end

@implementation LKEditorController

- (instancetype)initWithEditor:(UITextView<LKEditorEditProtocol> *)editor {
    self = [super init];
    if (self) {
        self.editor = editor;
        self.showKeyboard = NO;
        self.actionType = TextFormattingStyleNormal;
        [self addKeyboardNotifications];
        [self configDefaultValue];
    }
    return self;
}

- (void)configDefaultValue {
    // 获取主窗口
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    // 获取底部安全范围的高度
    bottomSafeAreaHeight = 0;
    if (@available(iOS 11.0, *)) {
        bottomSafeAreaHeight = mainWindow.safeAreaInsets.bottom;
    }
}

// 自定义工具栏位置
- (void)showTextToolBarInView:(UIView *)showView {
    NSAssert(showView, @"父view不能nil");
    if (!showView) return;
    [showView addSubview:self.toolBarView];
    
    [self refreshToolBarFrame];
    
}
- (void)refreshToolBarFrame {
    if (self.toolBarView.superview) {
        CGFloat bottomOffset = self.showKeyboard ? (-keyboardHeight) : (-bottomSafeAreaHeight);
        [self.toolBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.bottom.offset(bottomOffset);
            make.height.mas_equalTo([self toolBarHeight]);
        }];
    }
}

- (CGFloat)toolBarHeight {
    CGFloat height = Editor_ToolBar_Height;
    if (_actionType == TextFormattingStyleImage) {
        height = Editor_ImageSelected_Height + Editor_ToolBar_Height;
    }
    return height;
}

#pragma mark - LKEditorToolBarViewDelegate 工具栏点击事件
- (void)toolBarClickTextFormattingStyle:(TextFormattingStyle)style withActionValue:(id)value {
    if (_actionType == TextFormattingStyleFontSize || _actionType == TextFormattingStyleImage) {
        [self.editor resignFirstResponder];
        [self.editor becomeFirstResponder];
    }
    _actionType = style;
    switch (style) {
        case TextFormattingStyleBold:
        case TextFormattingStyleItatic:
        case TextFormattingStyleUnderline:
        case TextFormattingStyleNormal: {
            [self.editor toolBarItemSelectedStateAction:style withActionValue:value];
            break;
        }
        case TextFormattingStyleImage: {
            [self.editor endEditing:YES];
            [self refreshToolBarFrame];
            self.imagePicker.hidden = NO;
            [self.imagePicker showWithTextEditor:self.editor completion:^(UIImage * _Nonnull pickerImage) {
                [self.editor toolBarItemSelectedStateAction:style withActionValue:pickerImage];
            }];
            // 当输入光标被遮挡时，将光标移动到可见范围
            [self.editor scrollRangeToVisible:self.editor.selectedRange];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Getter && setter
/// 输入框
- (void)setEditor:(UITextView<LKEditorEditProtocol> *)editor {
    _editor = editor;
    _editor.delegate = self;
    
}
/** 工具栏*/
- (LKEditorToolBarView *)toolBarView {
    if (!_toolBarView) {
        _toolBarView = [[LKEditorToolBarView alloc] init];
        _toolBarView.delegate = self;
    }
    return _toolBarView;
}

/// 图片选择界面
- (LKEditorImagePicker<LKEditorImagePickerProtocol> *)imagePicker {
    if (_imagePicker) return _imagePicker;
    _imagePicker = [[LKEditorImagePicker alloc] init];
    [_toolBarView addSubview:_imagePicker];
    [_imagePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.equalTo(_toolBarView.mas_top).offset(Editor_ToolBar_Height);
        make.height.mas_equalTo(Editor_ImageSelected_Height);
    }];
    return _imagePicker;
}

#pragma - mark keyboard Notifications

- (void)addKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];

}
- (void)removeKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
#pragma mark -- UITextViewDelegate 输入框编辑状态变化
/** 开始编辑*/
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (_actionType == TextFormattingStyleImage) {
        self.imagePicker.hidden = YES;
        _actionType = TextFormattingStyleNormal;
        [self.toolBarView updateToolBarItemSelectedState:TextFormattingStyleImage withActionValue:@(NO)];
        [self refreshToolBarFrame];
    }
}
/** 结束编辑*/
- (void)textViewDidEndEditing:(UITextView *)textView {
    [self refreshToolBarFrame];
}
#pragma mark -- 键盘变化
- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    // Orientation
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // User Info
    NSDictionary *info = notification.userInfo;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    // 获取键盘的 frame
    CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Toolbar Sizes
//    CGFloat sizeOfToolbar = [self toolBarHeight];
    
    // Keyboard Size
    //Checks if IOS8, gets correct keyboard height
    if (keyboardHeight == 0) {
        keyboardHeight = UIInterfaceOrientationIsLandscape(orientation) ? ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.000000) ? keyboardEnd.size.height : keyboardEnd.size.width : keyboardEnd.size.height;
    }
    // Correct Curve
    UIViewAnimationOptions animationOptions = curve << 16;
    
    if ([notification.name isEqualToString:UIKeyboardDidShowNotification] ||
        [notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        self.showKeyboard = YES;
    } else {
        self.showKeyboard = NO;
    }
    
    /*======计算输入框的start========
    // 获取输入框的文本范围
    UITextPosition *cursorPosition = [self.editor selectedTextRange].start;
    CGRect caretRect = [self.editor caretRectForPosition:cursorPosition];
    //将 caretRect 转换为相对于输入框父视图的坐标。
    CGRect caretInParentView = [self.editor convertRect:caretRect toView:self.editor.superview];
    // 如果光标被键盘遮挡，需要调整textView的contentOffset
    CGFloat offsetNeeded = CGRectGetMaxY(caretInParentView) - (keyboardEnd.origin.y - [self toolBarHeight]); // 10.0是额外的偏移

    // 判断交点是否在键盘的上方，如果不是，说明键盘遮挡了输入框
    if (offsetNeeded > 0) {
        // 键盘遮挡了输入框，可以根据需要执行相应的操作
        if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {

            [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
                UIEdgeInsets insets = self.editor.contentInset;
                insets.bottom = fabs(offsetNeeded);
                self.editor.contentInset = insets;
            } completion:nil];
        } else {
            [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
                UIEdgeInsets insets = self.editor.contentInset;
                insets.bottom = fabs(offsetNeeded);
                self.editor.contentInset = insets;
            } completion:^(BOOL finished) { }];
        }

    }
    ======计算输入框的end========*/
    /*======计算工具栏的start========*/
    if (self.toolBarView.superview != self.editor.inputAccessoryView) {
        // 计算键盘与屏幕底部的交点
        CGPoint toolBarIntersectionPoint = CGPointMake(CGRectGetMidX(self.toolBarView.bounds), CGRectGetMaxY(self.toolBarView.bounds)) ;
        toolBarIntersectionPoint = [self.toolBarView convertPoint:toolBarIntersectionPoint toView:self.toolBarView.superview];
        
        // 判断交点是否在键盘的上方，如果不是，说明键盘遮挡了输入框
        if (toolBarIntersectionPoint.y > keyboardEnd.origin.y) {
            // 键盘遮挡了输入框，可以根据需要执行相应的操作
            if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
                [UIView animateWithDuration:duration delay:0.3 options:animationOptions animations:^{
                    [self.toolBarView mas_updateConstraints:^(MASConstraintMaker *make) {
                        make.bottom.offset(-self->keyboardHeight);
                        make.height.mas_equalTo([self toolBarHeight]);
                    }];
                    [self.toolBarView layoutIfNeeded];
                } completion:nil];
            }

        }

    }
}

- (void)dealloc {
    [self removeKeyboardNotifications];
}


@end
