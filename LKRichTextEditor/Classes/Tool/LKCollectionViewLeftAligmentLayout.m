//
//  LKCollectionViewLeftAligmentLayout.m
//  LKRichTextEditor
//
//  Created by 李考 on 2023/11/10.
//

#import "LKCollectionViewLeftAligmentLayout.h"

@implementation LKCollectionViewLeftAligmentLayout
- (void)prepareLayout {
    [super prepareLayout];
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *superAttrs = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *attrs = [NSMutableArray arrayWithArray:superAttrs];

    for (UICollectionViewLayoutAttributes *attr in superAttrs) {
        // 当同一组只有一个item时，默认居中显示，调整默认靠左显示
        if (attr.representedElementCategory == UICollectionElementCategoryCell) {
            NSInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:attr.indexPath.section];
            if (numberOfItemsInSection == 1) {
                attr.frame = CGRectMake(self.sectionInset.left, attr.frame.origin.y, attr.size.width, attr.size.height);
            }
        }
    }
    return attrs;

}
@end
