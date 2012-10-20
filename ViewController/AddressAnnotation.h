//
//  AddressAnnotation.h
//  Nimbler Caltrain
//
//  Created by Carl on 10/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class AddressAnnotation;

@interface AddressAnnotation : NSObject <MKAnnotation>
{
  CLLocationCoordinate2D coordinate;
  //NSString *mTitle;
  //NSString *mSubTitle;
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D) coord;

@end
