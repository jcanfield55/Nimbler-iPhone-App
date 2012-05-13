//
//  ToFromTableTextFieldView.h
//  Nimbler
//
//  Created by John Canfield on 5/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

// This subclass is implemented so that I can handle typing reload and get focus back
// on the textField after typing has caused a reload of the To or From table

#import <UIKit/UIKit.h>

@interface ToFromTableTextFieldView : UITextField

@property (nonatomic) BOOL isTypingReload; // True if we just reloaded the tableView due to updated typing.  Cleared after focus is restored to txtField
@end
