//
//  LKCollectionImagePickerCell.h
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/10.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKCollectionImagePickerCell : UICollectionViewCell

@property (nonatomic, strong) UIImage *thumbImage;

@property (nonatomic, strong) PHAsset *pictureModel;
/** 是否是选中状态*/
@property (nonatomic, assign) BOOL selectedState;

/** 点击选择按钮*/
- (void)chooseThePicuteActionCompletion:(void(^)(PHAsset * chooseModel))completionhandle;

@end

NS_ASSUME_NONNULL_END
