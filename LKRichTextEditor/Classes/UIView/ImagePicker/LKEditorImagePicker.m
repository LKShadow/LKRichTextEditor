//
//  LKEditorImagePicker.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/9.
//

#import "LKEditorImagePicker.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Masonry/Masonry.h>
#import "LKCollectionViewLeftAligmentLayout.h"
#import "LKCollectionImagePickerCell.h"
#import "LKUISystemPhotoTool.h"
#import <LKRichTextEditor/UIImage+Editor.h>
@interface LKEditorImagePicker () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIImagePickerController *pickerController;
@property (nonatomic, copy) void (^selectImage)(UIImage *image);
/** 显示照片*/
@property (strong, nonatomic) UICollectionView *collectionView;
/** 底部工具栏*/
@property (nonatomic, strong) UIView *bottomToolView;
/** 相册按钮*/
@property (nonatomic, strong) UIButton *albumBtn;
/** 原图按钮*/
@property (nonatomic, strong) UIButton *origenAlbumBtn;
/** 编辑按钮*/
@property (nonatomic, strong) UIButton *pictureEditBtn;
/** 发送按钮/确认选择按钮*/
@property (nonatomic, strong) UIButton *sureSelectedBtn;

/***=========数据源==========**/
@property (nonatomic, strong) NSMutableArray <PHAsset *>*pictureAssets; //所有照片
/** 已选择的相册*/
@property (nonatomic, strong) NSMutableArray <PHAsset *>*choosePictures;
/** 显示的图片高度 默认280，最终通过计算获得不一定是280*/
@property (nonatomic, assign) CGFloat showImageHeight;

@end
#define kSpaceSlide 20.0
#define kSpaceImageView 10.0
#define kShowCollectionImageCount 20 // 半屏显示默认的照片个数
#define kShowPictureBottomSizeHeigth 50 // 设定的图片底部工具栏显示高度
@implementation LKEditorImagePicker

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.canEditing = YES;
        self.maxPictureCount = 9;
        self.showImageHeight = 280;
        [self initSubviews];
        [self requestPhotoLibraryPermission];
    }
    return self;
}

- (void)layoutSubviews {
    self.showImageHeight = self.frame.size.height - kShowPictureBottomSizeHeigth;
    [super layoutSubviews];
}

- (void)initSubviews {
    self.pictureAssets = [NSMutableArray arrayWithCapacity:kShowCollectionImageCount];
    self.choosePictures = [NSMutableArray array];
    
//    // 获取主窗口
//    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
//    // 获取底部安全范围的高度
//    CGFloat bottomSafeAreaHeight = 0;
//    if (@available(iOS 11.0, *)) {
//        bottomSafeAreaHeight = mainWindow.safeAreaInsets.bottom;
//    }
//    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 280 + 50 + bottomSafeAreaHeight);

    
    [self addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.equalTo(self.mas_top);
        make.bottom.offset(-50);
    }];
    
    [self addSubview:self.bottomToolView];
    [self.bottomToolView addSubview:self.albumBtn];
    [self.bottomToolView addSubview:self.origenAlbumBtn];
    [self.bottomToolView addSubview:self.pictureEditBtn];
    [self.bottomToolView addSubview:self.sureSelectedBtn];
    
    [self.bottomToolView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.bottom.offset(0).priorityLow();
        make.top.equalTo(self.collectionView.mas_bottom);
        make.height.mas_greaterThanOrEqualTo(50);
    }];
    [self.albumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(20);
        make.top.offset(10);
        make.width.mas_lessThanOrEqualTo(80);
        make.width.mas_greaterThanOrEqualTo(50);
        make.height.mas_equalTo(30);
    }];
    [self.origenAlbumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.albumBtn.mas_centerY);
        make.left.equalTo(self.albumBtn.mas_right).offset(18);
        make.width.mas_greaterThanOrEqualTo(80);
        make.width.mas_lessThanOrEqualTo(160);
        make.height.mas_equalTo(30);
    }];
    [self.sureSelectedBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-15);
        make.centerY.equalTo(self.albumBtn.mas_centerY);
        make.width.mas_greaterThanOrEqualTo(74);
        make.width.mas_lessThanOrEqualTo(90);
        make.height.mas_equalTo(30);
    }];
    [self.pictureEditBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.sureSelectedBtn.mas_left).offset(-18);
        make.centerY.equalTo(self.albumBtn.mas_centerY);
        make.height.mas_equalTo(30);
        make.left.equalTo(self.origenAlbumBtn.mas_right).offset(5).priorityLow();
        make.width.mas_greaterThanOrEqualTo(50);
    }];

}

/** 选择变化，修改对应的状态显示*/
- (void)updateBottomToolView {
    if (self.origenAlbumBtn.isSelected && self.choosePictures.count > 0) {
        NSArray *assets = [self.choosePictures copy];
        [self calculateTotalSizeForAssets:assets completion:^(NSString *totalSize) {
            [self.origenAlbumBtn setTitle:[NSString stringWithFormat:@"原图(%@)",totalSize] forState:UIControlStateSelected];
        }];
    }
    if (self.choosePictures.count > 0) {
        [self.sureSelectedBtn setTitle:[NSString stringWithFormat:@"发送(%ld/%d)",self.choosePictures.count,self.maxPictureCount] forState:UIControlStateNormal];
        self.sureSelectedBtn.enabled = YES;
        self.sureSelectedBtn.backgroundColor = COLOR_HEX(0x3da5fe);
    } else {
        self.sureSelectedBtn.enabled = NO;
        [self.sureSelectedBtn setTitle:@"发送" forState:UIControlStateNormal];
        [self.sureSelectedBtn setBackgroundColor:[UIColor grayColor]];
    }
}
- (void)calculateTotalSizeForAssets:(NSArray<PHAsset *> *)assets completion:(void (^)(NSString *totalSize))completion {
    dispatch_group_t group = dispatch_group_create();
    __block NSUInteger totalFileSize = 0;
    
    for (id assetObject in assets) {
        dispatch_group_enter(group);
        PHAsset *asset = (PHAsset *)assetObject;
        [LKUISystemPhotoTool fetchImageDataForAsset:asset completion:^(NSData * _Nonnull imageData, NSString * _Nonnull uti, UIImageOrientation orientation) {
            if (imageData) {
                totalFileSize += imageData.length;
            }
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 所有异步操作都已完成
        NSString *sizeString = [LKUISystemPhotoTool formattedSizeStringFromBytes:totalFileSize];
        completion(sizeString);
    });
}

#pragma mark - LKEditorImagePickerProtocol

- (void)showWithTextEditor:(UITextView *)textView completion:(void (^)(UIImage * _Nonnull))completion {
    if (completion) {
        self.selectImage = completion;
    }
//    if ([textView.inputAccessoryView isKindOfClass:[LKEditorToolBarView class]]) {
//        textView.inputView = self;
//        [textView resignFirstResponder];
//        [textView becomeFirstResponder];
//    }
    
}
/** 已获得授权，请求本地相册数据*/
- (void)requestPhotolibraryData {
    // 获取所有相册
    PHFetchResult *allAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    int count = 0;

    // 遍历相册获取照片
    for (PHAssetCollection *album in allAlbums) {
        PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:album options:nil];
        for (PHAsset *asset in assets) {
            // 处理照片
            // 这里可以将PHAsset对象添加到你的数据源中
            if (count > 20) break;
            if ([self.pictureAssets containsObject:asset]) {
                continue;// 移除重复图片
            } else if (asset.mediaType == PHAssetMediaTypeImage) {// 目前只支持图片
                [self.pictureAssets addObject:asset];
                count ++;
            }
            
        }
    }
    [self.collectionView reloadData];
}
#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.pictureAssets.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LKCollectionImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([LKCollectionImagePickerCell class]) forIndexPath:indexPath];
    if (indexPath.row < self.pictureAssets.count) {
        PHAsset *asset = self.pictureAssets[indexPath.row];
        // 计算自适应的宽度
        CGFloat targetWidth = (CGFloat)asset.pixelWidth / asset.pixelHeight * self.showImageHeight;
        CGSize pictureSize = CGSizeMake(targetWidth, self.showImageHeight);
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:pictureSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            cell.thumbImage = result;
        }];
        cell.pictureModel = asset;
        cell.selectedState = [self judgePictureSelectedState:asset];
        __weak typeof(self) weakSelf = self;
        [cell chooseThePicuteActionCompletion:^(PHAsset * _Nonnull chooseModel) {
            if ([weakSelf.choosePictures containsObject: chooseModel]) {
                [weakSelf.choosePictures removeObject:chooseModel];
            } else {
                if (weakSelf.choosePictures.count > (weakSelf.maxPictureCount - 1)) {
                    [LKUISystemPhotoTool showAlertFromView:self withMessage:[NSString stringWithFormat:@"最多选择%d张图片或视频",self.maxPictureCount]];
                    return;
                }
                [weakSelf.choosePictures addObject:chooseModel];
            }
            cell.selectedState = [weakSelf judgePictureSelectedState:chooseModel];
            [weakSelf updateBottomToolView];
        }];
    }
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.pictureAssets.count) {
        PHAsset *asset = self.pictureAssets[indexPath.row];
        // 计算自适应的宽度
        CGFloat targetWidth = (CGFloat)asset.pixelWidth / asset.pixelHeight * self.showImageHeight;
        CGSize pictureSize = CGSizeMake(targetWidth, self.showImageHeight);
        return pictureSize;
    }
    return CGSizeMake(self.showImageHeight, self.showImageHeight);
}
#pragma mark - Event
/** 相册点击事件*/
- (void)clickAlbumEvent:(UIButton *)btn {
    
}
/** 原图点击事件*/
- (void)clickOrigenAlbumEvent:(UIButton *)btn {
    self.origenAlbumBtn.selected = !btn.isSelected;
    [self updateBottomToolView];
}
/** 点击编辑事件*/
- (void)clickEditingImageEvent:(UIButton *)btn {
    
}
/** 点击发送或者确认事件*/
- (void)clickSureSelectedImageEvent:(UIButton *)btn {
    if (self.choosePictures.count > 0) {
        NSArray <PHAsset *>* list = self.choosePictures;
        [self processAssetsWithDelay:list currentIndex:0];
    }
    [self updateBottomToolView];
}

- (void)processAssetsWithDelay:(NSArray<PHAsset *> *)assets currentIndex:(NSUInteger)index {
    if (index >= assets.count) {
        [self.choosePictures removeAllObjects];
        [self.collectionView reloadData];
        return;
    }

    __weak typeof(self) weakSelf = self;
    PHAsset *as = assets[index];
    
    [LKUISystemPhotoTool fetchImageDataForAsset:as completion:^(NSData * _Nonnull imageData, NSString * _Nonnull uti, UIImageOrientation orientation) {
        UIImage *origenImage = [UIImage imageWithData:imageData];
        UIImage *editImage = origenImage;// 是否压缩，默认压一半
        if (!weakSelf.origenAlbumBtn.isSelected) {
            editImage = [LKUISystemPhotoTool compressionTheImaeg:origenImage maxMemory:300];
        }
        if (weakSelf.selectImage) {
            weakSelf.selectImage(editImage);
        }
        [weakSelf processAssetsWithDelay:assets currentIndex:index + 1];
    }];
}

/** 判断当前相片是否是选中状态*/
- (BOOL)judgePictureSelectedState:(PHAsset *)asset {
    for (PHAsset *as in self.choosePictures) {
        if ([as.localIdentifier isEqualToString:asset.localIdentifier]) {
            return YES;
        }
    }
    return NO;
}
#pragma mark - Setter
- (void)setCanEditing:(BOOL)canEditing {
    _canEditing = canEditing;
    self.pictureEditBtn.hidden = !canEditing;
}
#pragma mark - 相册权限请求
- (void)requestPhotoLibraryPermission {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status) {
        case PHAuthorizationStatusAuthorized:
            [self requestPhotolibraryData]; // 相册权限已授权，可以直接打开相册
            break;
        case PHAuthorizationStatusNotDetermined:{
            // 尚未请求权限，需要请求用户授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus newStatus) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (newStatus == PHAuthorizationStatusAuthorized) {
                        [self requestPhotolibraryData];
                    } else {
                        [self handlePhotoLibraryPermissionDenied];
                    }
                });
            }];
            break;
        }
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            [self handlePhotoLibraryPermissionDenied]; // 处理用户拒绝权限的情况
            break;
        case PHAuthorizationStatusLimited:
            [self handleLimitedPhotoLibraryPermission]; // 处理相册权限受限的情况
            break;
    }
}

- (void)handlePhotoLibraryPermissionDenied {
    // 处理相册权限被拒绝的情况，可以提示用户去设置中开启权限
    NSLog(@"相册权限被拒绝或受限");
    [self showAlertToOpenPhotoLibraryPermission];
}

- (void)handleLimitedPhotoLibraryPermission {
    // 处理相册权限受限的情况，通常在这里提供一个界面，让用户选择照片
    [self requestPhotolibraryData];
}

- (void)showAlertToOpenPhotoLibraryPermission {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"相册权限被拒绝"message:@"请前往设置->隐私->照片开启相册权限" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 跳转到应用的设置页面
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:settingsURL];
            }
        }
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:settingsAction];
    
    UIViewController *rootController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootController presentViewController:alertController animated:YES completion:nil];
}
#pragma mark - UI
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        LKCollectionViewLeftAligmentLayout *layout = [[LKCollectionViewLeftAligmentLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 10;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 30);
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[LKCollectionImagePickerCell class] forCellWithReuseIdentifier:NSStringFromClass([LKCollectionImagePickerCell class])];
    }
    return _collectionView;
}
- (UIView *)bottomToolView {
    if (!_bottomToolView) {
        _bottomToolView = [[UIView alloc] init];
    }
    return _bottomToolView;
}
- (UIButton *)albumBtn {
    if (!_albumBtn) {
        _albumBtn = [[UIButton alloc] init];
        _albumBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_albumBtn setTitle:@"相册" forState:UIControlStateNormal];
        [_albumBtn setTitleColor:COLOR_HEX(0x3da5fe) forState:UIControlStateNormal];
        [_albumBtn addTarget:self action:@selector(clickAlbumEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _albumBtn;
}
- (UIButton *)origenAlbumBtn {
    if (!_origenAlbumBtn) {
        _origenAlbumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _origenAlbumBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _origenAlbumBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_origenAlbumBtn setTitle:@"原图" forState:UIControlStateNormal];
        [_origenAlbumBtn setImage:[[UIImage resourceWithImageName:@"Picture_Origen_unSelected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        [_origenAlbumBtn setTitleColor:COLOR_HEX(0x666666) forState:UIControlStateNormal];
        [_origenAlbumBtn setTitleColor:COLOR_HEX(0x3da5fe) forState:UIControlStateSelected];
        [_origenAlbumBtn setImage:[[UIImage resourceWithImageName:@"Picture_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
        [_origenAlbumBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
        [_origenAlbumBtn addTarget:self action:@selector(clickOrigenAlbumEvent:) forControlEvents:UIControlEventTouchUpInside];
        _origenAlbumBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _origenAlbumBtn;
}
- (UIButton *)pictureEditBtn {
    if (!_pictureEditBtn) {
        _pictureEditBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _pictureEditBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _pictureEditBtn.hidden = !_canEditing;
        [_pictureEditBtn setTitle:@"编辑" forState:UIControlStateNormal];
        [_pictureEditBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_pictureEditBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_pictureEditBtn addTarget:self action:@selector(clickEditingImageEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pictureEditBtn;
}

- (UIButton *)sureSelectedBtn {
    if (!_sureSelectedBtn) {
        _sureSelectedBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_sureSelectedBtn setTitle:@"发送" forState:UIControlStateNormal];
        [_sureSelectedBtn setBackgroundColor:[UIColor grayColor]];
        [_sureSelectedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _sureSelectedBtn.layer.cornerRadius = 15;
        _sureSelectedBtn.layer.masksToBounds = YES;
        _sureSelectedBtn.enabled = NO;
        [_sureSelectedBtn addTarget:self action:@selector(clickSureSelectedImageEvent:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _sureSelectedBtn;
}

@end
