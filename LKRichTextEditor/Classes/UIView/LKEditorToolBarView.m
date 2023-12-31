//
//  LKEditorToolBarView.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/8.
//

#import "LKEditorToolBarView.h"
#import "UIImage+Editor.h"

/// 工具栏的高度，宽度默认屏幕宽度
static CGFloat const Editor_ToolBar_Height = 40;

@interface LKEditorToolBarView (){
    CGFloat _itemWidth;// 单个item的宽度
}

/** 数据源*/
@property (nonatomic, strong) NSArray *formattingStyles;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
/// 存储所有的按钮 以类型为key
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIButton *> *actionCache;

@end

@implementation LKEditorToolBarView


- (instancetype)init {
    self = [super init];
    if (self) {
        self.actionCache = [NSMutableDictionary dictionary];
        _itemWidth = 50;
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    
    self.backgroundColor = [UIColor whiteColor];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-_itemWidth, self.frame.size.height)];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:scrollView];
    _scrollView = scrollView;
    
    if (@available(iOS 11.0, *)) {
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.distribution = UIStackViewDistributionFillEqually;
    [scrollView addSubview:stackView];
    _stackView = stackView;

//    CALayer *line = [CALayer layer];
//    line.backgroundColor = [UIColor lightGrayColor].CGColor;
//    line.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1);
//    [self.layer addSublayer:line];
}
- (void)updateToolbarItems:(NSArray *)styles {
    self.formattingStyles = styles;
    [self configToolBar];
}
/** 配置功能按钮*/
- (void)configToolBar {
    for (UIView *view in _stackView.subviews) {
        [view removeFromSuperview];
    }
    [self.actionCache removeAllObjects];
    
    NSArray *items = [self.formattingStyles copy];
    for (int i = 0; i < items.count; i++) {
        UIButton *itemButton = [[UIButton alloc] init];
        TextFormattingStyle style = [items[i] integerValue];
        itemButton.tag = style;
        [itemButton setImage:[self itemImageName:style] forState:UIControlStateNormal];
        [itemButton setImage:[self itemSelectedImageName:style] forState:UIControlStateSelected];
        [itemButton addTarget:self action:@selector(onToolButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionCache setObject:itemButton forKey:@(style)];
        [_stackView addArrangedSubview:itemButton];
    }

//    _scrollView.contentSize = CGSizeMake(_itemWidth * items.count , self.frame.size.height);
//    _stackView.frame = CGRectMake(0, 0, _scrollView.contentSize.width, _scrollView.contentSize.height);

}
- (void)layoutSubviews {
    [super layoutSubviews];
    NSArray *items = [self.formattingStyles copy];
    _scrollView.frame = CGRectMake(0, 0, self.frame.size.width, Editor_ToolBar_Height);
    _scrollView.contentSize = CGSizeMake(_itemWidth * items.count , Editor_ToolBar_Height);
    _stackView.frame = CGRectMake(0, 0, _scrollView.contentSize.width, _scrollView.contentSize.height);
}

/** 工具栏按钮点击事件*/
- (void)onToolButtonTapped:(UIButton *)button {
    TextFormattingStyle style = button.tag;
    UIButton *tapBtn = [self.actionCache objectForKey:@(style)];
    switch (style) {
        case TextFormattingStyleDismiss:
        case TextFormattingStyleBold:
        case TextFormattingStyleItatic:
        case TextFormattingStyleUnderline: {
            tapBtn.selected = !tapBtn.isSelected;

            UIButton *imgBtn = [self.actionCache objectForKey:@(TextFormattingStyleImage)];
            imgBtn.selected = NO;// 移除相册的选中效果
            if ([self.delegate respondsToSelector:@selector(toolBarClickTextFormattingStyle:withActionValue:)]) {
                [self.delegate toolBarClickTextFormattingStyle:style withActionValue:@(tapBtn.isSelected)];
            }
            break;
        }
        case TextFormattingStyleImage: {
            if (button.isSelected) return;
            tapBtn.selected = YES;
            if ([self.delegate respondsToSelector:@selector(toolBarClickTextFormattingStyle:withActionValue:)]) {
                [self.delegate toolBarClickTextFormattingStyle:style withActionValue:nil];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)updateToolBarItemSelectedState:(TextFormattingStyle)style withActionValue:(id)value {
    UIButton *button = [self.actionCache objectForKey:@(style)];
    switch (style) {
        case TextFormattingStyleBold:
        case TextFormattingStyleItatic:
        case TextFormattingStyleUnderline: {
            button.selected = [value boolValue];
        }
            break;
        case TextFormattingStyleImage: {
            button.selected = [value boolValue];
            break;
        }
            
        default:
            break;
    }
}

// 获取item的图片
- (UIImage *)itemImageName:(TextFormattingStyle)style {
    NSString *iconName;
    switch (style) {
        case TextFormattingStyleBold:
            iconName = @"Editor_bold";
            break;
        case TextFormattingStyleItatic:
            iconName = @"Editor_itatic";
            break;
        case TextFormattingStyleUnderline:
            iconName = @"Editor_underline";
            break;
        case TextFormattingStyleFontSize:
            iconName = @"Editor_fontSize";
            break;
        case TextFormattingStyleColor:
            iconName = @"Editor_textColor";
            break;
        case TextFormattingStyleImage:
            iconName = @"Editor_image";
            break;
        case TextFormattingStyleDismiss:
            iconName = @"Editor_toolBar_dismiss";
            break;
        default:
            iconName = nil;
            break;
    }
    UIImage *image = [UIImage resourceWithImageName:iconName];
    return image;
}
// 获取item的选中状态图片
- (UIImage *)itemSelectedImageName:(TextFormattingStyle)style {
    NSString *iconName;
    switch (style) {
        case TextFormattingStyleBold:
            iconName = @"Editor_bold_selected";
            break;
        case TextFormattingStyleItatic:
            iconName = @"Editor_itatic_selected";
            break;
        case TextFormattingStyleUnderline:
            iconName = @"Editor_underline_selected";
            break;
        case TextFormattingStyleFontSize:
            iconName = @"Editor_fontSize_selected";
            break;
        case TextFormattingStyleColor:
            iconName = @"Editor_textColor_selected";
            break;
        case TextFormattingStyleImage:
            iconName = @"Editor_image_selected";
            break;
        case TextFormattingStyleDismiss:
            iconName = @"Editor_toolBar_dismiss";
            break;
        default:
            iconName = nil;
            break;
    }
    return [UIImage resourceWithImageName:iconName];
}


@end
