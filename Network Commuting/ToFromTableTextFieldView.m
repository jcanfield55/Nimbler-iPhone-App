//
//  ToFromTableTextFieldView.m
//  Nimbler
//
//  Created by John Canfield on 5/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "ToFromTableTextFieldView.h"

@implementation ToFromTableTextFieldView

@synthesize isTypingReload;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Override didMoveToWindow so I can tell whether this view needs to become first responder
- (void)didMoveToWindow {
    // If this is a typing reload case, and the view is now visible in a window, get back firstResponder status
    if ([self window] && isTypingReload) { 
            [self becomeFirstResponder];
            isTypingReload= FALSE;
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
