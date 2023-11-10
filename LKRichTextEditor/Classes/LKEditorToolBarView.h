//
//  LKEditorToolBarView.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/8.
//

#import <UIKit/UIKit.h>
#import "LKEditorTextView.h"
NS_ASSUME_NONNULL_BEGIN

/// 工具栏的高度，宽度默认屏幕宽度
static CGFloat const Editor_ToolBar_Height = 40;

@protocol LKEditorToolBarViewDelegate <NSObject>

@optional
/** 点击工具栏中对应的按钮事件及选择状态(或对应值)*/
- (void)toolBarClickTextFormattingStyle:(TextFormattingStyle)style withActionValue:(id _Nullable)value;

@end

@interface LKEditorToolBarView : UIView

- (void)updateToolbarItems:(NSArray *)styles;
/** 更新状态来对应的选中状态状态*/
- (void)updateToolBarItemSelectedState:(TextFormattingStyle)style withActionValue:(id _Nullable)value;

@property (nonatomic, weak) id <LKEditorToolBarViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
