//
//  LKCollectionImagePickerCell.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/10.
//

#import "LKCollectionImagePickerCell.h"
#import <Masonry/Masonry.h>
#import "UIImage+Editor.h"
#import "LKUISystemPhotoTool.h"
@interface LKCollectionImagePickerCell ()

@property (nonatomic, strong) UIImageView *pictureView;

@property (nonatomic, strong) UIButton *selectedBtn;
@property (nonatomic, strong) UIView *maskView;
// 用于显示视频格式的时长及标识
@property (nonatomic, strong) UIImageView *videoIconView;
@property (nonatomic, strong) UILabel *videoTimeLabel;

/** 是否是视频，视频需要传入 时长参数*/
@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, assign) NSTimeInterval videoTime;

@property (nonatomic, copy) void (^choosePictureBlock)(PHAsset *chooseModel);
@end

@implementation LKCollectionImagePickerCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    [self.contentView addSubview:self.pictureView];
    
    [self.pictureView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    [self.contentView addSubview:self.maskView];
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    [self.contentView addSubview:self.selectedBtn];
    [self.selectedBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(10);
        make.right.offset(-10);
        make.width.height.mas_equalTo(40);
    }];
    
    [self.contentView addSubview:self.videoIconView];
    [self.contentView addSubview:self.videoTimeLabel];
    
    [self.videoIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(5);
        make.bottom.offset(-5);
//        make.height.mas_equalTo(20);
    }];
    [self.videoTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-5);
        make.centerY.equalTo(self.videoIconView.mas_centerY);
    }];
}

- (void)setPictureModel:(PHAsset *)pictureModel {
    _pictureModel = pictureModel;
    if (_pictureModel.mediaType == PHAssetMediaTypeVideo) {
        self.isVideo = YES;
        self.videoTime = _pictureModel.duration;
    } else {
        self.isVideo = NO;
    }
}

- (void)setSelectedState:(BOOL)selectedState {
    _selectedState = selectedState;
    self.selectedBtn.selected = selectedState;
    self.maskView.hidden = !selectedState;
}

- (void)setThumbImage:(UIImage *)thumbImage {
    _thumbImage = thumbImage;
    self.pictureView.image = _thumbImage;
}

- (void)setIsVideo:(BOOL)isVideo {
    _isVideo = isVideo;
    self.videoIconView.hidden = !isVideo;
    self.videoTimeLabel.hidden = !isVideo;
}

- (void)setVideoTime:(NSTimeInterval)videoTime {
    _videoTime = videoTime;
    if (videoTime > 0) {
        self.videoTimeLabel.text = [NSString stringWithFormat:@"%@",[LKUISystemPhotoTool formattedStringFromTimeInterval:_videoTime] ?: @""];
    }
}

- (void)chooseThePicuteActionCompletion:(void (^)(PHAsset * _Nonnull))completionhandle {
    if (completionhandle) {
        self.choosePictureBlock = completionhandle;
    }
}

/** 点击选择按钮事件*/
- (void)clickSelectedEvent:(UIButton *)btn {
    self.selectedBtn.selected = !btn.isSelected;
    self.maskView.hidden = !self.selectedBtn.isSelected;
    self.choosePictureBlock(_pictureModel);
}
/** 点击照片事件，触发查看大图*/
- (void)clickPictureToShowBigViewEvent {
    NSLog(@"点击图片");
}

#pragma mark - UI
- (UIImageView *)pictureView {
    if (!_pictureView) {
        _pictureView = [[UIImageView alloc] init];
        _pictureView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickPictureToShowBigViewEvent)];
        [_pictureView addGestureRecognizer:tap];
    }
    return _pictureView;
}
- (UIButton *)selectedBtn {
    if (!_selectedBtn) {
        _selectedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectedBtn setImage:[UIImage resourceWithImageName:@"Picture_unSelected"] forState:UIControlStateNormal];
        [_selectedBtn setImage:[UIImage resourceWithImageName:@"Picture_selected"] forState:UIControlStateSelected];
        [_selectedBtn addTarget:self action:@selector(clickSelectedEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectedBtn;
}

- (UIImageView *)videoIconView {
    if (!_videoIconView) {
        _videoIconView = [[UIImageView alloc] init];
        _videoIconView.image = [UIImage resourceWithImageName:@"Picture_Video"];
        _videoIconView.hidden = YES;
    }
    return _videoIconView;
}
- (UILabel *)videoTimeLabel {
    if (!_videoTimeLabel) {
        _videoTimeLabel = [[UILabel alloc] init];
        _videoTimeLabel.textColor = [UIColor whiteColor];
        _videoTimeLabel.textAlignment = NSTextAlignmentRight;
        _videoTimeLabel.font = [UIFont systemFontOfSize:15];
        _videoTimeLabel.hidden = YES;
    }
    return _videoTimeLabel;
}


- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        _maskView.userInteractionEnabled = NO;
        _maskView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.8];
        _maskView.hidden = YES;
    }
    return _maskView;
}


@end
