//
//  LKEditorManager.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/10.
//

#import <Foundation/Foundation.h>
#import "LKRichTextEditor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKEditorController : NSObject

- (instancetype)initWithEditor:(UITextView <LKEditorEditProtocol>*)editor;

@property (nonatomic, strong, readonly) LKEditorToolBarView *toolBarView;

/** 记录keyboard的显示状态*/
@property (nonatomic, assign, readonly) BOOL showKeyboard;

/**
 * 将工具栏显示在指定view上, 默认位置是在键盘顶部
 */
- (void)showTextToolBarInView:(UIView *)showView;
@end

NS_ASSUME_NONNULL_END
