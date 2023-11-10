//
//  UIImage+Editor.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/8.
//

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

@end
