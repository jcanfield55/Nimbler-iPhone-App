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
        //if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
//            UIImageView *backView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 49)];
//            [backView setImage:[UIImage imageNamed:@"img_tabbar@2x.png"]];
//            [self.view addSubview:backView];
//        }
//        else{
//           [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"img_tabbar.png"]]]; 
//        }
    UIImage *btnImage;
    UIImage *btnImageSelected;
	self.btn1 = [UIButton buttonWithType:UIButtonTypeCustom]; //Setup the button
    
    // Accessibility Label For UI Automation.
    self.btn1.accessibilityLabel = TRIP_PLANNER_BUTTON;
    
         if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
             btn1.frame = CGRectMake(NAVIGATION_ITEM1_XPOS, 0, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT_4INCH); // Set the frame (size and position) of the button)
             btnImage = [UIImage imageNamed:@""];
             btnImageSelected = [UIImage imageNamed:@"img_selTrip@2x.png"];
         }
         else{
             btn1.frame = CGRectMake(NAVIGATION_ITEM1_XPOS, 0, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT); // Set the frame (size and position) of the button)
             btnImage = [UIImage imageNamed:@""];
             btnImageSelected = [UIImage imageNamed:@"img_selTrip.png"];
         }
    [btn1 setTitle:@"Notifications" forState:UIControlStateNormal];
    //[btn1 setBackgroundImage:btnImage forState:UIControlStateNormal]; // Set the image for the normal state of the button
	//[btn1 setBackgroundImage:btnImageSelected forState:UIControlStateSelected]; // Set the image for the selected state of the button
	[btn1 setTag:0]; // Assign the button a "tag" so when our "click" event is called we know which button was pressed.
	
	// Now we repeat the process for the other buttons
    
	
    self.btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Accessibility Label For UI Automation.
     self.btn2.accessibilityLabel = ADVISORIES_BUTTON;
    
    
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            btn2.frame = CGRectMake(NAVIGATION_ITEM2_XPOS, 0, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT_4INCH);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selAdvisory@2x.png"];
        }
        else{
            btn2.frame = CGRectMake(NAVIGATION_ITEM2_XPOS, 0, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selAdvisory.png"];
        }
    [btn2 setTitle:@"Settings" forState:UIControlStateNormal];
	//[btn2 setBackgroundImage:btnImage forState:UIControlStateNormal];
	//[btn2 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn2 setTag:1];
	
	self.btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Accessibility Label For UI Automation.
    self.btn3.accessibilityLabel = SETTINGS_BUTTON;
    
        if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            btn3.frame = CGRectMake(NAVIGATION_ITEM3_XPOS, 0, NAVIGATION_ITEM_WIDTH-0.8, NAVIGATION_ITEM_HEIGHT_4INCH);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selSetting@2x.png"];
        }
        else{
            btn3.frame = CGRectMake(NAVIGATION_ITEM3_XPOS, 0, NAVIGATION_ITEM_WIDTH-0.8, NAVIGATION_ITEM_HEIGHT);
            btnImage = [UIImage imageNamed:@""];
            btnImageSelected = [UIImage imageNamed:@"img_selSetting.png"];
        }
    [btn3 setTitle:@"Feedback" forState:UIControlStateNormal];
	//[btn3 setBackgroundImage:btnImage forState:UIControlStateNormal];
	//[btn3 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn3 setTag:2];
		
	// Add my new buttons to the view
	[self.view addSubview:btn1];
	[self.view addSubview:btn2];
	[self.view addSubview:btn3];
	
    [btn1.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    [btn2.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    [btn3.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    
	// Setup event handlers so that the buttonClicked method will respond to the touch up inside event.
    [btn1 addTarget:self action:@selector(buttonClicked1:) forControlEvents:UIControlEventTouchDown];
	[btn2 addTarget:self action:@selector(buttonClicked1:) forControlEvents:UIControlEventTouchDown];
	[btn3 addTarget:self action:@selector(buttonClicked1:) forControlEvents:UIControlEventTouchDown];
	[btn1 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn2 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn3 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	//[btn4 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    int lastSelectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:LAST_SELECTED_TAB_INDEX];
    if(lastSelectedIndex == 0){
        [btn1 setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
        [btn2 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
        [btn3 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
        [btn1 setSelected:true];
    }
    else if(lastSelectedIndex == 1){
        [btn2 setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
        [btn1 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
        [btn3 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
        [btn2 setSelected:true];
    }
    else if(lastSelectedIndex == 2){
        [btn3 setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
        [btn2 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
        [btn1 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
         [btn3 setSelected:true];
    }
}

- (void)buttonClicked1:(id)sender
{
	int tagNum = [sender tag];
	[self selectTab1:tagNum];
}

- (void)buttonClicked:(id)sender
{
	int tagNum = [sender tag];
	[self selectTab:tagNum];
}

- (void)selectTab1:(int)tabID
{
	switch(tabID)
	{
		case 0:
			[btn1 setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
			[btn2 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
            [btn3 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
			break;
		case 1:
			[btn2 setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
			[btn1 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
            [btn3 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
			break;
		case 2:
			[btn3 setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
			[btn2 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
            [btn1 setBackgroundColor:[UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0]];
			break;
	}
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

@end
