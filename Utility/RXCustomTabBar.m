//
//  RumexCustomTabBar.m
//  
//
//  Created by Oliver Farago on 19/06/2010.
//  Copyright 2010 Rumex IT All rights reserved.
//

#import "RXCustomTabBar.h"
#import "nc_AppDelegate.h"

@implementation RXCustomTabBar

@synthesize btn1, btn2, btn3, btn4;
@synthesize barBackground;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self hideTabBar];
	[self addCustomElements];
}

- (void)hideTabBar
{
    /*
	for(UIView *view in self.view.subviews)
	{
		if([view isKindOfClass:[UITabBar class]])
		{
			view.hidden = YES;
			break;
		}
	} */
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
    UIImage *btnImage;
    UIImage *btnImageSelected;
    
    if (!(btn1 && btn2 && btn3 && barBackground)) {  // only create buttons if they have not already been created
        self.btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        self.btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
        self.btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
        self.barBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0,UI_STATUS_BAR_HEIGHT,
                                                                      self.view.frame.size.width - REVEAL_CONTROLLER_RIGHT_MARGIN,
                                                                      NAVIGATION_ITEM_HEIGHT)];
        
        UIImage *barImage = [UIImage imageNamed:@"tabBarBackground@2x.png"];
        [self.barBackground setImage:barImage];
        
        // Accessibility Label For UI Automation.
        self.btn1.accessibilityLabel = TRIP_PLANNER_BUTTON;
        
        float navigation_button_gap = (self.view.frame.size.width - REVEAL_CONTROLLER_RIGHT_MARGIN - (3 * NAVIGATION_ITEM_WIDTH)) / 2.0; // This is the extra space between buttons
        navigation_button_gap = 0;   // Test: try not putting any gap at all.  
        btn1.frame = CGRectMake(NAVIGATION_ITEM1_XPOS,UI_STATUS_BAR_HEIGHT, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT);
        btn2.frame = CGRectMake(NAVIGATION_ITEM1_XPOS + 1 * (NAVIGATION_ITEM_WIDTH + navigation_button_gap),
                                UI_STATUS_BAR_HEIGHT, NAVIGATION_ITEM_WIDTH, NAVIGATION_ITEM_HEIGHT);
        btn3.frame = CGRectMake(NAVIGATION_ITEM1_XPOS + 2 * (NAVIGATION_ITEM_WIDTH + navigation_button_gap),
                                UI_STATUS_BAR_HEIGHT, NAVIGATION_ITEM_WIDTH-0.8, NAVIGATION_ITEM_HEIGHT);
        
        btnImage = [UIImage imageNamed:@"notificationUnSelected@2x.png"];
        btnImageSelected = [UIImage imageNamed:@"notificationSelected@2x.png"];
        [btn1 setBackgroundImage:btnImage forState:UIControlStateNormal];
        [btn1 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
        [btn1 setTag:0];
        [self selectTab:0];
        [nc_AppDelegate sharedInstance].isNotificationsButtonClicked = NO;
        
        // Accessibility Label For UI Automation.
        self.btn2.accessibilityLabel = ADVISORIES_BUTTON;
        btnImage = [UIImage imageNamed:@"settingUnSelected@2x.png"];
        btnImageSelected = [UIImage imageNamed:@"settingSelected@2x.png"];
        [btn2 setBackgroundImage:btnImage forState:UIControlStateNormal];
        [btn2 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
        [btn2 setTag:1];
        
        
        // Accessibility Label For UI Automation.
        self.btn3.accessibilityLabel = SETTINGS_BUTTON;
        btnImage = [UIImage imageNamed:@"feedBackUnSelected@2x.png"];
        btnImageSelected = [UIImage imageNamed:@"feedBackSelected@2x.png"];
        [btn3 setBackgroundImage:btnImage forState:UIControlStateNormal];
        [btn3 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
        [btn3 setTag:2];
        
        // Add my new buttons to the view
        [self.view addSubview:barBackground];
        [self.view addSubview:btn1];
        [self.view addSubview:btn2];
        [self.view addSubview:btn3];
        
        // Setup event handlers so that the buttonClicked method will respond to the touch up inside event.
        [btn1 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn2 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn3 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
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
            [nc_AppDelegate sharedInstance].isNotificationsButtonClicked = YES;
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

- (void) hideAllElements{
    [btn1 setHidden:YES];
    [btn2 setHidden:YES];
    [btn3 setHidden:YES];
}
- (void) showAllElements{
    [btn1 setHidden:NO];
    [btn2 setHidden:NO];
    [btn3 setHidden:NO];
}
@end
