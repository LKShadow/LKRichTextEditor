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
@interface LKViewController ()<LKEditorToolBarDataSourceDelegate,UITextViewDelegate>

@property (nonatomic, strong) LKEditorTextView *textView;
@end

@implementation LKViewController

- (void)viewDidLoad
{
    self.title = @"首页";
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    LKEditorTextView *textView = [[LKEditorTextView alloc] init];
    textView.toolBarDataSource = self;
    textView.placeholder = @"请输入文字";
    textView.delegate = self;
    textView.placeholderColor = [UIColor grayColor];
    textView.layer.borderColor = [UIColor blueColor].CGColor;
    textView.layer.borderWidth = 1;
//    textView.inputAccessoryView = textView.editorController.toolBarView;
    self.textView = textView;
    [self.view addSubview:textView];
    [textView.editorController showTextToolBarInView:self.view];

    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(100);
        make.centerX.equalTo(self.view.mas_centerX);
        make.left.offset(20);
        make.right.offset(-20);
        make.height.mas_equalTo(106);
    }];
    
}

- (NSArray<NSNumber *> *)supportToolBarItems {
    return @[@(TextFormattingStyleBold),@(TextFormattingStyleItatic),@(TextFormattingStyleUnderline),@(TextFormattingStyleImage)];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    NSLog(@"%@",textView.text);
    return YES;
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
