//
//  ViewController.m
//  KSStongTextLayout
//
//  Created by jft0m on 2019/3/10.
//  Copyright © 2019 jft. All rights reserved.
//

#import "ViewController.h"
#import "KSStoryBannerLayoutManager.h"

@interface ViewController () <UITextViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) KSStoryBannerLayoutManager *layoutManager;
@property (nonatomic, strong) NSTextContainer *textContainer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSTextStorage *textStorage = [NSTextStorage new];
    
    KSStoryBannerLayoutManager *layoutManager = [KSStoryBannerLayoutManager new];
    self.layoutManager = layoutManager;
    [textStorage addLayoutManager:layoutManager];
    
    NSTextContainer *textContainer = [NSTextContainer new];
    [layoutManager addTextContainer:textContainer];
    self.textContainer = textContainer;
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(20, 100, 300, 300) textContainer:textContainer];
    self.textView.delegate = self;
    self.textView.text = @"tessssssss";
    self.textView.font = [UIFont systemFontOfSize:64];
    [self.view addSubview:self.textView];
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSLayoutManager *layoutManager = textView.layoutManager;
    // the range of the line we are currently typing on
    NSMutableArray<NSValue *> *lineRanges = [NSMutableArray array];
    void (^block)(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop)
    = ^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
        NSRange characterRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        if (range.length) {/// 替换
            NSRange tRange = NSIntersectionRange(characterRange, range);
            if (tRange.length > 0) {
                [lineRanges addObject:[NSValue valueWithRange:characterRange]];
            }
        } else {// 插入
        if (characterRange.location <= range.location && NSMaxRange(characterRange) >= range.location ) {
                [lineRanges addObject:[NSValue valueWithRange:characterRange]];
            }
        }
    };
    [textView.layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, layoutManager.numberOfGlyphs)
                                                     usingBlock:block];
    if (!lineRanges.count) {
        NSLog(@"没找到行");
        return YES;
    }
    NSRange firstTpyingRange = lineRanges.firstObject.rangeValue;
    // 即将修改的新文本
    NSString *tText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSRange sizingTextRange = ({
        NSUInteger location = firstTpyingRange.location;
        NSRange rangeToDelete = NSIntersectionRange(firstTpyingRange, range);
        NSUInteger typingLengthToDelete = NSIntersectionRange(firstTpyingRange, rangeToDelete).length;
        NSUInteger length = firstTpyingRange.length - typingLengthToDelete + text.length;
        NSMakeRange(location, length);
    });
    if (tText.length < NSMaxRange(sizingTextRange)) {
        NSLog(@"算错了");
        return YES;
    }
    NSString *sizingText = [tText substringWithRange:sizingTextRange];
    if (sizingText.length) {
        CGFloat calculatedFontSize = [self preferredFontSize:sizingText
                                      textViewContainerWidth:textView.textContainer.size.width - 10];
        NSMutableDictionary *typingAttributes = [textView.typingAttributes mutableCopy];
        UIFontDescriptor *fontDescriptor = [(UIFont *)typingAttributes[NSFontAttributeName] fontDescriptor];
        typingAttributes[NSFontAttributeName] = [UIFont fontWithDescriptor:fontDescriptor
                                                                      size:calculatedFontSize];
        textView.typingAttributes = typingAttributes;

        NSTextStorage *textStorage = textView.textStorage;
        [textStorage setAttributes:typingAttributes range:firstTpyingRange];
        NSLog(@"[calculatedFontSize] - [%@]", @(calculatedFontSize));
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    NSMutableArray<NSValue *> *lineRanges = [NSMutableArray array];
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSTextStorage *textStorage = textView.textStorage;
    [textView.layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, layoutManager.numberOfGlyphs)
                                                     usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
                                                         NSRange characterRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
                                                         [lineRanges addObject:[NSValue valueWithRange:characterRange]];
                                                     }];
    [textStorage beginEditing];

    NSString *text = textView.text;
    NSMutableDictionary *typingAttributes = [textView.typingAttributes mutableCopy];
    UIFontDescriptor *fontDescriptor = [(UIFont *)typingAttributes[NSFontAttributeName] fontDescriptor];

    for (NSValue *lineRangeValue in lineRanges) {
        NSRange lineRange = lineRangeValue.rangeValue;
        NSString *lineText = [text substringWithRange:lineRange];
        const CGFloat fontSize = [self preferredFontSize:lineText textViewContainerWidth:textView.bounds.size.width - 10];
        [textStorage setAttributes:@{NSFontAttributeName : [UIFont fontWithDescriptor:fontDescriptor size:fontSize]} range:lineRange];
    }
    [textStorage endEditing];
}

- (CGFloat)preferredFontSize:(NSString *)string textViewContainerWidth:(CGFloat)textViewContainerWidth {
    // 让文字尽量一行展示得下
    CGFloat const minimumFontSize = 35.f;
    CGFloat const maximumFontSize = 150.f;
    CGFloat const pointSize = 24;// 随便给一个就可以
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string
                                                                           attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:pointSize] }];
    CGFloat textWidth = CGRectGetWidth([attributedString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                                      options:NULL
                                                                      context:nil]);
    CGFloat scaleFactor = (textViewContainerWidth / ceil(textWidth));
    CGFloat preferredFontSize = floor(pointSize * scaleFactor);
    preferredFontSize = MAX(preferredFontSize, minimumFontSize);
    preferredFontSize = MIN(preferredFontSize, maximumFontSize);
    return preferredFontSize;
}

@end
