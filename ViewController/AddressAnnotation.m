//
//  AddressAnnotation.m
//  Nimbler Caltrain
//
//  Created by Carl on 10/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "AddressAnnotation.h"

@implementation AddressAnnotation

@synthesize coordinate;
@synthesize title, subtitle;

/*
- (NSString *)subtitle
{
  return mSubTitle;
}

- (void)setSubtitle:(NSString *)subtitle
{
  mSubTitle = subtitle;
}

- (NSString *)title
{
  return mTitle;
}

- (void)setTitle:(NSString *)title;
{
  mTitle = title;
}
*/

- (id)initWithCoordinate:(CLLocationCoordinate2D) coord
{
  coordinate = coord;
  //mTitle = @"Title";
  //mSubTitle = @"Subtitle";
  title = @"Title";
  subtitle = @"subtitle";
  
  return self;
}

@end
