//
//  LKEditorImagePicker.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/9.
//

#import "LKEditorImagePicker.h"
#import <Photos/Photos.h>

@interface LKEditorImagePicker () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *pickerController;
@property (nonatomic, copy) void (^selectImage)(UIImage *image);

@end

@implementation LKEditorImagePicker

- (UIImagePickerController *)pickerController {
    if (_pickerController) return _pickerController;
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerController.allowsEditing = YES;
    pickerController.delegate = self;
    _pickerController = pickerController;
    return pickerController;
}

- (void)showWithCompletion:(void (^)(UIImage * _Nonnull))completion {
    if (completion) {
        self.selectImage = completion;
    }
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status) {
        case PHAuthorizationStatusAuthorized:
            [self presentImagePickerController]; // 相册权限已授权，可以直接打开相册
            break;
        case PHAuthorizationStatusNotDetermined:{
            // 尚未请求权限，需要请求用户授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus newStatus) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (newStatus == PHAuthorizationStatusAuthorized) {
                        [self presentImagePickerController];
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

- (void)presentImagePickerController {
    UIViewController *rootController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootController presentViewController:self.pickerController animated:YES completion:nil];
}

- (void)handlePhotoLibraryPermissionDenied {
    // 处理相册权限被拒绝的情况，可以提示用户去设置中开启权限
    NSLog(@"相册权限被拒绝或受限");
    [self showAlertToOpenPhotoLibraryPermission];
}

- (void)handleLimitedPhotoLibraryPermission {
    // 处理相册权限受限的情况，通常在这里提供一个界面，让用户选择照片
    [self presentImagePickerController];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = nil;
    if ([picker allowsEditing]) { // 获取用户编辑之后的图像
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else { // 照片的元数据参数
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    _selectImage(image);
    _selectImage = nil;
    [picker dismissViewControllerAnimated:YES completion:^{}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    _selectImage(nil);
    _selectImage = nil;
    [picker dismissViewControllerAnimated:YES completion:^{}];
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

@end
