//
//  IterableFullScreenViewController.m
//  Iterable-iOS-SDK

//  Created by David Truong on 8/24/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

#import "IterableFullScreenViewController.h"
#import "IterableConstants.h"
#import "IterableInAppManager.h"

@interface IterableFullScreenViewController ()
@property (nonatomic, strong) UIImageView* ImageView;
@property (nonatomic) NSArray *actionButtons;

@property (nonatomic, strong) UILabel* Title;
@property (nonatomic, strong) UILabel* TextBody;
@property (nonatomic, strong) UIStackView* DialogButtons;

@property (nonatomic) NSString *imageURL;
@property (nonatomic) int backgroundColor;

@property (nonatomic) NSString *titleFontName;
@property (nonatomic) int titleColor;
@property (nonatomic) NSString *titleString;

@property (nonatomic) NSString *bodyTextFontName;
@property (nonatomic) int bodyTextColor;
@property (nonatomic) NSString *bodyTextString;

@end

@implementation IterableFullScreenViewController

CGFloat imageWidth = 0;
CGFloat imageHeight = 0;

// documented in IterableFullScreenViewController.h
-(void)ITESetData:(NSDictionary *)jsonPayload {
    if ([jsonPayload objectForKey:ITERABLE_IN_APP_TITLE]) {
        NSDictionary* title = [jsonPayload objectForKey:ITERABLE_IN_APP_TITLE];
        _titleFontName = [title objectForKey:ITERABLE_IN_APP_TEXT_FONT];
        _titleColor = [IterableInAppManager getIntColorFromKey:title keyString:ITERABLE_IN_APP_TEXT_COLOR];
        _titleString = [title objectForKey:ITERABLE_IN_APP_TEXT];
    }
    
    if ([jsonPayload objectForKey:ITERABLE_IN_APP_BODY]) {
        NSDictionary* body = [jsonPayload objectForKey:ITERABLE_IN_APP_BODY];
        _bodyTextFontName = [body objectForKey:ITERABLE_IN_APP_TEXT_FONT];
        _bodyTextColor = [IterableInAppManager getIntColorFromKey:body keyString:ITERABLE_IN_APP_TEXT_COLOR];
        _bodyTextString = [body objectForKey:ITERABLE_IN_APP_TEXT];
    }
    
    if ([jsonPayload objectForKey:ITERABLE_IN_APP_BUTTONS]) {
        _actionButtons = [jsonPayload objectForKey:ITERABLE_IN_APP_BUTTONS];
    }
    
    _imageURL = [jsonPayload objectForKey:ITERABLE_IN_APP_IMAGE];
    
    _backgroundColor = [IterableInAppManager getIntColorFromKey:jsonPayload keyString:ITERABLE_IN_APP_BACKGROUND_COLOR];
}

/**
 @method
 
 @abstract Creates a custom view hierarchy for the dialog
 */
- (void)loadView {
    [super loadView];
    
    UIColor *backgroundColor = UIColorFromRGB(_backgroundColor);
    [self.view setBackgroundColor:backgroundColor];
    
    NSInteger fontConstant = (self.view.frame.size.width > self.view.frame.size.height) ? self.view.frame.size.width : self.view.frame.size.height;
    
    self.Title = [[UILabel alloc] initWithFrame:CGRectZero];
    self.Title.textAlignment =  NSTextAlignmentCenter;
    self.Title.textColor = UIColorFromRGB(_titleColor);
    self.Title.font = [UIFont fontWithName: self.titleFontName size:(fontConstant/16)];
    self.Title.text = self.titleString;
    self.Title.numberOfLines = 2;
    self.Title.adjustsFontSizeToFitWidth = YES;
    
    _ImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    if(_imageURL != nil) {
        //Async load of the center image
        [self processImageDataWithURLString:self.imageURL setImage:^(NSData *imageData) {
            if (self.view.window) {
                UIImage *image = [UIImage imageWithData:imageData];
                imageWidth = image.size.width;
                imageHeight = image.size.height;
                _ImageView.image = image;
                
                [self layoutCenterImage];
            }
        }];
    }
    
    self.DialogButtons = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.DialogButtons.frame = CGRectMake(0, self.view.frame.size.height*.9f, self.view.frame.size.width, self.view.frame.size.height*.1f);
    self.DialogButtons.distribution = UIStackViewDistributionFillEqually;
    
    for (int i =0; i <_actionButtons.count; i++)
    {
        NSDictionary *buttonParams = [_actionButtons objectAtIndex:i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        [self ITEAddActionButton:button.tag actionString:[buttonParams objectForKey:ITERABLE_IN_APP_BUTTON_ACTION]];
        [button addTarget:self
                   action:@selector(ITEActionButtonClicked:)
         forControlEvents:UIControlEventTouchUpInside];


         if ([buttonParams objectForKey:ITERABLE_IN_APP_CONTENT]) {
             NSDictionary* buttonContent = [buttonParams objectForKey:ITERABLE_IN_APP_CONTENT];
             if ([buttonContent objectForKey:ITERABLE_IN_APP_TEXT_FONT]) {
                 NSString *font = [buttonContent objectForKey:ITERABLE_IN_APP_TEXT_FONT];
                 [button.titleLabel setFont:[UIFont fontWithName:font size:(fontConstant/30)]];
             }
             if ([buttonContent objectForKey:ITERABLE_IN_APP_TEXT_COLOR]) {
                 int buttonTextColor = [IterableInAppManager getIntColorFromKey:buttonContent keyString:ITERABLE_IN_APP_TEXT_COLOR];
                 [button setTitleColor:UIColorFromRGB(buttonTextColor) forState:UIControlStateNormal];
             }
             NSString *title = [buttonContent objectForKey:ITERABLE_IN_APP_TEXT];
             [button setTitle:title forState:UIControlStateNormal];

         }
        
        button.backgroundColor = UIColorFromRGB([IterableInAppManager getIntColorFromKey:buttonParams keyString:ITERABLE_IN_APP_BACKGROUND_COLOR]);
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.DialogButtons addArrangedSubview:button];
    }
   
    self.TextBody = [[UILabel alloc] initWithFrame:CGRectZero];
    self.TextBody.textAlignment =  NSTextAlignmentCenter;
    self.TextBody.textColor = UIColorFromRGB(_bodyTextColor);
    self.TextBody.font = [UIFont fontWithName:self.bodyTextFontName size:(fontConstant/30)];
    self.TextBody.text = self.bodyTextString;
    self.TextBody.adjustsFontSizeToFitWidth = YES;
    
    [self.view addSubview:_ImageView];
    [self.view addSubview:self.Title];
    [self.view addSubview:self.DialogButtons];
    [self.view addSubview:self.TextBody];
}

/**
 @method
 
 @abstract Loads an image from the specified urlString and dispatches the processImage callback when completed.
 
 @param urlString the url to load the image from
 @param setImage the action block to be called after loading the image
 
 */
- (void)processImageDataWithURLString:(NSString *)urlString setImage:(void (^)(NSData *imageData))setImage
{
    NSURL *url = [NSURL URLWithString:urlString];
    
    dispatch_queue_t loadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(loadQueue, ^{
        NSData * imageData = [NSData dataWithContentsOfURL:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            setImage(imageData);
        });
    });
}

/**
 @method
 
 @abstract  Called just before the view controller's view's layoutSubviews method is invoked.
 */
- (void)viewWillLayoutSubviews {
    CGPoint img = [self layoutCenterImage];
    
    //Float title halfway between image and top
    CGFloat titleSizeY = _ImageView.center.y - img.y/2;
    self.Title.frame = CGRectMake(0, 0, self.view.frame.size.width*.9, titleSizeY);
    [self.Title setCenter:CGPointMake(self.view.frame.size.width/2, titleSizeY/2)];
    
    //Action Button
    self.DialogButtons.frame = CGRectMake(0, self.view.frame.size.height*.9f, self.view.frame.size.width, self.view.frame.size.height*.1f);
    
    //Main Text
    CGFloat textBodyStartingLocation = _ImageView.center.y + img.y/2;
    self.TextBody.frame = CGRectMake(0, textBodyStartingLocation, self.view.frame.size.width*.8f, self.view.frame.size.height*.9f - textBodyStartingLocation);
    [self.TextBody setCenter:CGPointMake(self.view.center.x, textBodyStartingLocation+self.TextBody.frame.size.height/2)];
}

/**
 @method
 
 @abstract Layouts the dialog by centering the image then adjusting the
 
 @return a CGPoint representing the size of the center image
 */
-(CGPoint)layoutCenterImage{
    float maxHeight;
    if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
    {
        maxHeight = self.view.frame.size.height*.5;
        self.TextBody.numberOfLines = 2;
        
    } else {
        maxHeight = self.view.frame.size.width * 3/4; //4:3 aspect ratio
        self.TextBody.numberOfLines = 4;
    }
    
    float newHeight = maxHeight;
    float newWidth = self.view.frame.size.width;
    
    //Center Image
    if (_ImageView.image != NULL) {
        float maxWidth = self.view.frame.size.width;
        float scaleFactor = maxWidth / imageWidth;
        if (imageHeight*scaleFactor > maxHeight) {
            scaleFactor = maxHeight / imageHeight;
        }
        newHeight = imageHeight * scaleFactor;
        newWidth = imageWidth * scaleFactor;
    }
    _ImageView.frame = CGRectMake(0, 0, newWidth, newHeight);
    [_ImageView setCenter:CGPointMake(self.view.center.x, self.view.center.y*.9f)];
    return CGPointMake(newWidth, newHeight);
}


@end


