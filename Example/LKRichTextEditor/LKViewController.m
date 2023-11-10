//
//  LKViewController.m
//  LKRichTextEditor
//
//  Created by 李考 on 11/07/2023.
//  Copyright (c) 2023 李考. All rights reserved.
//

#import "LKViewController.h"
#import <LKRichTextEditor.h>
#import <Masonry/Masonry.h>
@interface LKViewController ()<LKRichTextEditorDelegate>

@property (nonatomic, strong) LKEditorTextView *textView;
@end

@implementation LKViewController

- (void)viewDidLoad
{
    self.title = @"首页";
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    LKEditorTextView *textView = [[LKEditorTextView alloc] init];
    textView.toolBarDelegate = self;
    textView.placeholder = @"请输入文字";
    textView.placeholderColor = [UIColor grayColor];
    textView.layer.borderColor = [UIColor blueColor].CGColor;
    textView.layer.borderWidth = 1;
    self.textView = textView;
    [self.view addSubview:textView];
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(100);
        make.centerX.equalTo(self.view.mas_centerX);
        make.left.offset(20);
        make.right.offset(-20);
        make.height.mas_equalTo(300);
    }];
    
}

- (NSArray *)supportToolBarItems {
    return @[@(TextFormattingStyleBold),@(TextFormattingStyleItatic),@(TextFormattingStyleUnderline),@(TextFormattingStyleImage)];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
