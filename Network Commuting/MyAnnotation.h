//
//  MyAnnotation.h
//  Nimbler
//
//  Created by JaY Kumbhani on 5/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyAnnotation : NSObject<MKAnnotation> {
	
	CLLocationCoordinate2D	coordinate;
	NSString*				title;
	NSString*				subtitle;
}

@property (nonatomic, assign)	CLLocationCoordinate2D	coordinate;
@property (nonatomic, copy)		NSString*				title;
@property (nonatomic, copy)		NSString*				subtitle;

@end