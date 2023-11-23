//
//  UIImage+Editor.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/8.
//
#import <CommonCrypto/CommonDigest.h>
#import "UIImage+Editor.h"
#import "LKEditorTextView.h"
@implementation UIImage (Editor)

+ (UIImage *)resourceWithImageName:(NSString *)imageName {
    if (!imageName || imageName.length == 0) {
        return nil;
    }
    static NSBundle *resourceBoundle = nil;
    if (!resourceBoundle) {
        NSBundle *mainBoundle = [NSBundle bundleForClass:[LKEditorTextView class]];
        NSString *sourcePath = [mainBoundle pathForResource:@"LKRichTextEditor" ofType:@"bundle"];
        resourceBoundle = [NSBundle bundleWithPath:sourcePath] ?: mainBoundle;
    }
    UIImage *icon = [UIImage imageNamed:imageName inBundle:resourceBoundle compatibleWithTraitCollection:nil];
    return icon;

}

- (NSString *)calculateMD5ForImage {
    // 将 UIImage 转换为 NSData
    NSData *imageData = UIImagePNGRepresentation(self);
    
    // 使用 CommonCrypto 计算 MD5
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(imageData.bytes, (CC_LONG)imageData.length, md5Buffer);
    // 将二进制数据转换为十六进制字符串
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", md5Buffer[i]];
    }
    
    return [md5String copy];
}

@end
