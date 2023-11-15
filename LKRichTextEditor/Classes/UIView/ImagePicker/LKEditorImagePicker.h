//
//  LKEditorImagePicker.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/9.
//

#import <Foundation/Foundation.h>
#import <LKRichTextEditor/LKRichTextEditor.h>
NS_ASSUME_NONNULL_BEGIN
@interface LKEditorImagePicker : UIView<LKEditorImagePickerProtocol>

/** 是否显示编辑按钮，默认显示*/
@property (nonatomic, assign) BOOL canEditing;
/** 最大选择的图片个数，默认9个*/
@property (nonatomic, assign) int maxPictureCount;
@end

NS_ASSUME_NONNULL_END
