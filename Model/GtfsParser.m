//
//  GtfsParser.m
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "GtfsParser.h"
#import "GtfsAgency.h"
#import "UtilityFunctions.h"

@implementation GtfsParser

@synthesize managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
    }
    
    return self;
}

- (void) parseAgencyDataAndStroreToDataBase:(NSString *)strFileData{
    NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyURL = [[NSMutableArray alloc] init];

    //Temporary We have Separated with == we will change that with \n.
    NSArray *arrayComponents = [strFileData componentsSeparatedByString:@"=="];
    for(int i=0;i<[arrayComponents count];i++){
        NSString *strSubComponents = [arrayComponents objectAtIndex:i];
        NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
        if([arraySubComponents count] > 0){
            [arrayAgencyID addObject:[arraySubComponents objectAtIndex:0]];
        }
        else{
            [arrayAgencyID addObject:@""];
        }
        if([arraySubComponents count] > 1){
            [arrayAgencyName addObject:[arraySubComponents objectAtIndex:1]];
        }
        else{
            [arrayAgencyName addObject:@""];
        }
        if([arraySubComponents count] > 2){
            [arrayAgencyURL addObject:[arraySubComponents objectAtIndex:2]];
        }
        else{
            [arrayAgencyURL addObject:@""];
        }
    }
    for(int i=0;i<[arrayAgencyID count];i++){
        GtfsAgency* agency = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsAgency" inManagedObjectContext:self.managedObjectContext];
        agency.agencyID = [arrayAgencyID objectAtIndex:i];
        agency.agencyName = [arrayAgencyName objectAtIndex:i];
        agency.agencyURL = [arrayAgencyURL objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
    
}


@end
