//
//  UIFont+TextFormat.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/8.
//

#import "UIFont+TextFormat.h"

@implementation UIFont (TextFormat)

- (BOOL)isBold {
    return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) > 0;
}

- (BOOL)isItatic {
    return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) > 0;
}

- (CGFloat)fontSize {
    return [self.fontDescriptor.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
}

- (UIFont *)copyWithItatic:(BOOL)isItatic {
    return [self copyWithSymbolicTrait:UIFontDescriptorTraitItalic add:isItatic];
}

- (UIFont *)copyWithBold:(BOOL)isBold {
    return [self copyWithSymbolicTrait:UIFontDescriptorTraitBold add:isBold];
}

- (UIFont *)copyWithFontSize:(CGFloat)fontSize {
    return [UIFont fontWithDescriptor:self.fontDescriptor size:fontSize];
}

- (UIFont *)copyWithSymbolicTrait:(UIFontDescriptorSymbolicTraits)symbolicTrait add:(BOOL)isAdd {
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits;
    BOOL currentSymbolicTrait = (symbolicTraits & symbolicTrait) > 0;
    if (!currentSymbolicTrait && isAdd) {
        symbolicTraits |= symbolicTrait;
    }
    if (currentSymbolicTrait && !isAdd) {
        symbolicTraits &= (~symbolicTrait);
    }
    UIFontDescriptor * fontDescriptor = [self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
    // 保持新UIFont实例的大小与原始UIFont实例相同
    CGFloat pointSize = self.pointSize;

    if ((symbolicTraits & UIFontDescriptorTraitItalic) > 0) {
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(20 * (CGFloat)M_PI / 180), 1, 0, 0);
        fontDescriptor = [fontDescriptor fontDescriptorWithMatrix:matrix];
    } else {
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(0 * (CGFloat)M_PI / 180), 1, 0, 0);
        fontDescriptor = [fontDescriptor fontDescriptorWithMatrix:matrix];
    }
    return [UIFont fontWithDescriptor:fontDescriptor size:pointSize];
}

@end
