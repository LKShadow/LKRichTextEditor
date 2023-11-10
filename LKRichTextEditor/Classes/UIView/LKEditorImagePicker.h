//
//  LKEditorImagePicker.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/9.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@protocol LKEditorImagePickerProtocol

- (void)showWithTextEditor:(UITextView *)textView completion:(void (^) (UIImage *pickerImage))completion;

@end
@interface LKEditorImagePicker : UIView<LKEditorImagePickerProtocol>

@end

NS_ASSUME_NONNULL_END
