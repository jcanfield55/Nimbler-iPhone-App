//
//  UberDetailViewController.m
//  Nimbler SF
//
//  Created by John Canfield on 9/12/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import "UberDetailViewController.h"
#import "UtilityFunctions.h"
#import "Logging.h"

@interface UberDetailViewController ()

@end

@implementation UberDetailViewController

@synthesize mainTable;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //[[self navigationItem] setTitle:@"Pick a location"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    logEvent(FLURRY_UBER_DETAILS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    
    mainTable.delegate = self;
    mainTable.dataSource = self;
    [mainTable reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
