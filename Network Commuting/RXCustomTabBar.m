//
//  RumexCustomTabBar.m
//  
//
//  Created by Oliver Farago on 19/06/2010.
//  Copyright 2010 Rumex IT All rights reserved.
//

#import "RXCustomTabBar.h"

@implementation RXCustomTabBar

@synthesize btn1, btn2, btn3, btn4;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self hideTabBar];
	[self addCustomElements];
}

- (void)hideTabBar
{
	for(UIView *view in self.view.subviews)
	{
		if([view isKindOfClass:[UITabBar class]])
		{
			view.hidden = YES;
			break;
		}
	}
}

- (void)hideNewTabBar 
{
    self.btn1.hidden = 1;
    self.btn2.hidden = 1;
    self.btn3.hidden = 1;
    self.btn4.hidden = 1;
}

- (void)showNewTabBar 
{
    self.btn1.hidden = 0;
    self.btn2.hidden = 0;
    self.btn3.hidden = 0;
    self.btn4.hidden = 0;
}

-(void)addCustomElements
{
	// Initialise our two images
        if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            UIImageView *backView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 517, 320, 49)];
            [backView setImage:[UIImage imageNamed:@"img_tabbar.png"]];
            [self.view addSubview:backView];
        }
        else{
           [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"img_tabbar.png"]]]; 
        }
    UIImage *btnImage;
    UIImage *btnImageSelected;
	self.btn1 = [UIButton buttonWithType:UIButtonTypeCustom]; //Setup the button
         if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
             btn1.frame = CGRectMake(NAVIGATION_ITEM1_XPOS, NAVIGATION_ITEM_YPOS_4INCH, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT_4INCH); // Set the frame (size and position) of the button)
             btnImage = [UIImage imageNamed:@""];
             btnImageSelected = [UIImage imageNamed:@"img_selTrip.png"];
         }
         else{
             btn1.frame = CGRectMake(NAVIGATION_ITEM1_XPOS, NAVIGATION_ITEM_YPOS, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT); // Set the frame (size and position) of the button)
             btnImage = [UIImage imageNamed:@""];
             btnImageSelected = [UIImage imageNamed:@"img_selTrip.png"];
         }
    [btn1 setBackgroundImage:btnImage forState:UIControlStateNormal]; // Set the image for the normal state of the button
	[btn1 setBackgroundImage:btnImageSelected forState:UIControlStateSelected]; // Set the image for the selected state of the button
	[btn1 setTag:0]; // Assign the button a "tag" so when our "click" event is called we know which button was pressed.
	[btn1 setSelected:true]; // Set this button as selected (we will select the others to false as we only want Tab 1 to be selected initially
	
	// Now we repeat the process for the other buttons
	
    self.btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
        if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            btn2.frame = CGRectMake(NAVIGATION_ITEM2_XPOS, NAVIGATION_ITEM_YPOS_4INCH, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT_4INCH);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selAdvisory.png"];
        }
        else{
            btn2.frame = CGRectMake(NAVIGATION_ITEM2_XPOS, NAVIGATION_ITEM_YPOS, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selAdvisory.png"];
        }
	[btn2 setBackgroundImage:btnImage forState:UIControlStateNormal];
	[btn2 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn2 setTag:1];
	

	self.btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
        if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            btn3.frame = CGRectMake(NAVIGATION_ITEM3_XPOS, NAVIGATION_ITEM_YPOS_4INCH, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT_4INCH);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selSetting.png"];
        }
        else{
            btn3.frame = CGRectMake(NAVIGATION_ITEM3_XPOS, NAVIGATION_ITEM_YPOS, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selSetting.png"];
        }
	[btn3 setBackgroundImage:btnImage forState:UIControlStateNormal];
	[btn3 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn3 setTag:2];
	
    
	self.btn4 = [UIButton buttonWithType:UIButtonTypeCustom];
        if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            btn4.frame = CGRectMake(NAVIGATION_ITEM4_XPOS, NAVIGATION_ITEM_YPOS_4INCH, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT_4INCH);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selFB.png"];
        }
        else{
            btn4.frame = CGRectMake(NAVIGATION_ITEM4_XPOS, NAVIGATION_ITEM_YPOS, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selFB.png"]; 
        }
	[btn4 setBackgroundImage:btnImage forState:UIControlStateNormal];
	[btn4 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn4 setTag:3];
	
	// Add my new buttons to the view
	[self.view addSubview:btn1];
	[self.view addSubview:btn2];
	[self.view addSubview:btn3];
	[self.view addSubview:btn4];
	
	// Setup event handlers so that the buttonClicked method will respond to the touch up inside event.
	[btn1 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn2 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn3 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn4 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)buttonClicked:(id)sender
{
	int tagNum = [sender tag];
	[self selectTab:tagNum];
}

- (void)selectTab:(int)tabID
{
	switch(tabID)
	{
		case 0:
			[btn1 setSelected:true];
			[btn2 setSelected:false];
			[btn3 setSelected:false];
			[btn4 setSelected:false];
			break;
		case 1:
			[btn1 setSelected:false];
			[btn2 setSelected:true];
			[btn3 setSelected:false];
			[btn4 setSelected:false];
			break;
		case 2:
			[btn1 setSelected:false];
			[btn2 setSelected:false];
			[btn3 setSelected:true];
			[btn4 setSelected:false];
			break;
		case 3:
			[btn1 setSelected:false];
			[btn2 setSelected:false];
			[btn3 setSelected:false];
			[btn4 setSelected:true];
			break;
	}	
	self.selectedIndex = tabID;
	
}

// update badge
//-(void)updateBadge
//{
//    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//    int tweetConut = [[prefs objectForKey:@"tweetCount"] intValue];
//    [twitterCount removeFromSuperview];
//    tweetConut = 2;
//    twitterCount = [[CustomBadge alloc] init];
//    twitterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d",tweetConut]];
//    [twitterCount setFrame:CGRectMake(100,100, twitterCount.frame.size.width, twitterCount.frame.size.height)];        
//    if (tweetConut == 0) {
//        [twitterCount setHidden:YES];
//    } else {
//        [self.btn2 addSubview:twitterCount];
//        [twitterCount setHidden:NO];
//    }
//    
//}

@end
