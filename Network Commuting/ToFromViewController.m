//
//  ToFromViewController.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "ToFromViewController.h"

@implementation ToFromViewController
@synthesize fromField;
@synthesize toField;
@synthesize toAutoFill;
@synthesize fromAutoFill;
@synthesize rkGeoMgr;
@synthesize fromLocation;
@synthesize toLocation;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// One-time set-up of the RestKit Geocoder Object Manager's mapping

- (void)setRkGeoMgr:(RKObjectManager *)rkGeoMgr0
{
    rkGeoMgr = rkGeoMgr0;  //set the property

    // Add the mapper from Location class to this Object Manager
    [[rkGeoMgr mappingProvider] setMapping:[Location objectMappingforGeocoder:GOOGLE] forKeyPath:@"results"];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
        
    if (!cell) {
        cell = [[UITableViewCell alloc] 
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"UITableViewCell"];
    }
    
    // If this is the from table...
    if (tableView == fromAutoFill) {
        [[cell textLabel] setText:@"Current Location"];
    }
    else { // if this is the to table...
        [[cell textLabel] setText:@"Destination"];
    }
    return cell;
}

// Delegate for when text entered into the to: or from: UITextField
- (IBAction)toFromTextEntry:(id)sender forEvent:(UIEvent *)event 
{
    NSLog(@"Got into toFromTextEntry");
    
    NSString* rawAddress = [sender text];
    
    // Call the Geocoding web service to create a location object based on the rawAddress
    if ([rawAddress length] > 0) {
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: @"address", rawAddress, 
                                @"sensor", @"true", nil];
        NSString* resource = [@"json" appendQueryParams:params];
        NSLog(@"Parameter String = %@", resource);
        [rkGeoMgr loadObjectsAtResourcePath:resource delegate:self];
    }
}

// Delegate methods for when the RestKit has results from the Geocoder
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{    
    // Get the status string the hard way be parsing the response string
    NSString* response = [[objectLoader response] bodyAsString];
    NSRange range = [response rangeOfString:@"\"status\""];
    NSString* responseStartingFromStatus = [response substringFromIndex:(range.location+range.length)]; 
    NSArray* atoms = [responseStartingFromStatus componentsSeparatedByString:@"\""];
    NSString* status = [atoms objectAtIndex:1]; // status string is second atom (first after the first quote)
    NSLog(@"Status: %@", status);
    
    // Now use the object string
    NSLog(@"Object array:");
    Location* location = [objects objectAtIndex:0];
    NSLog(@"%@", location);
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
