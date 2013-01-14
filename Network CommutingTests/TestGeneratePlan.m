//
//  TestGeneratePlan.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 1/13/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//
// Test file for testing OTP completeness in generating all the scheduled combinations of routes for Caltrain per its stops and routes file
// This is a time consuming test, since it calls the server many times.  Should only be run occasionally and after hours.
// This test becomes somewhat less important after US202, since the app can generate all schedule combinations based on downloaded GTFS data. 

#import "TestGeneratePlan.h"
#import "PlanStore.h"
#import "nc_AppDelegate.h"
#import "UtilityFunctions.h"

@implementation TestGeneratePlan

- (void)setUp
{
    [super setUp];
    
    // Set-up test Core Data using an in-memory PSC
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    STAssertNotNil(managedObjectModel, @"Cannot create managedObjectModel instance");
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    STAssertNotNil(psc, @"Cannot create PersistentStoreCoordinator instance");
    
    NSError *error = nil;
    [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    STAssertNotNil(psc, @"Data store open failed for reason: %@", [error localizedDescription]);
    // RKObjectManager *rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TRIP_PROCESS_URL];
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:psc];
    [managedObjectContext setUndoManager:nil];
    
    // Set up Locations wrapper object pointing at the test Managed Object Context
    locations = [[Locations alloc] initWithManagedObjectContext:managedObjectContext rkGeoMgr:nil];
    
    // Set-up dates
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy hh:mm a"];
}

// US-186 partial Implementation

// Methods wait until Error or Reply arrives from TP.
-(void)someMethodToWaitForResult
{
    while (!([nc_AppDelegate sharedInstance].receivedReply^[nc_AppDelegate sharedInstance].receivedError))
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
}

// Compare The Leg Start Time With Departure time.
- (void)planTestWithComparingTime{
    BOOL isAnyTimeMatch = NO;
    Plan *plan = [nc_AppDelegate sharedInstance].testPlan;
    for(int j=0;j<[[plan sortedItineraries] count];j++){
        Itinerary *iti = [[plan sortedItineraries] objectAtIndex:j];
        for(int k=0;k<[[iti sortedLegs] count];k++){
            Leg *leg = [[iti sortedLegs]objectAtIndex:k];
            if([leg isTrain]){
                NSDate *date = [leg startTime];
                if(date){
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
                    int hour = [components hour];
                    int minute = [components minute];
                    NSString *strLegTime = [NSString stringWithFormat:@"%d:%d",hour,minute];
                    NSString *strTime = [nc_AppDelegate sharedInstance].expectedRequestDate;
                    NSArray *timeComponentArray = [strTime componentsSeparatedByString:@":"];
                    int startHour = [[timeComponentArray objectAtIndex:0] intValue];
                    if(startHour > 23){
                        startHour = startHour -24;
                    }
                    int startMinute = [[timeComponentArray objectAtIndex:1] intValue];
                    NSString *strStartTime = [NSString stringWithFormat:@"%d:%d",startHour,startMinute];
                    if([strLegTime isEqualToString:strStartTime]){
                        isAnyTimeMatch = YES;
                    }
                }
            }
        }
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logFile = [documentsDirectory stringByAppendingPathComponent:@"testlog.csv"];
    if(isAnyTimeMatch){
        [[nc_AppDelegate sharedInstance].testLogMutableString appendFormat:@"true\n"];
    }
    else{
        [[nc_AppDelegate sharedInstance].testLogMutableString appendFormat:@"false\n"];
    }
    NSData *logData = [[nc_AppDelegate sharedInstance].testLogMutableString dataUsingEncoding:NSUTF8StringEncoding];
    [logData writeToFile:logFile atomically:YES];
    STAssertTrue(isAnyTimeMatch, @"");
}



- (void)testGeneratePlans{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logFile = [documentsDirectory stringByAppendingPathComponent:@"testlog.csv"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:logFile]){
        [fileManager removeItemAtPath:logFile error:nil];
    }
    [nc_AppDelegate sharedInstance].testLogMutableString = [[NSMutableString alloc]init];
    [[nc_AppDelegate sharedInstance].testLogMutableString appendFormat:@"FromLocation,ToLocation,Departure Time,Trip ID,Test Result\n"];
    [nc_AppDelegate sharedInstance].isTestPlan = YES;
    NSMutableArray *arrayTripIds = [[NSMutableArray alloc] init];
    NSMutableArray *arrayArrivalTime = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDepartureTime = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopIds = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopSequences = [[NSMutableArray alloc] init];
    NSMutableArray *arrayPickUpTypes = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDropOfTypes = [[NSMutableArray alloc] init];
    NSMutableArray *arrayShapeDistTravelled = [[NSMutableArray alloc] init];
    
    // Parsing Data From stop_times.txt File
    NSString *strStopTimesFilePath = [[NSBundle mainBundle] pathForResource:@"stop_times" ofType:@"txt"];
    NSString *strStopTimesFileContent = [NSString stringWithContentsOfFile:strStopTimesFilePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *tempStopTimesDataArray = [strStopTimesFileContent componentsSeparatedByString:@"\n"];
    for(int i=1;i<[tempStopTimesDataArray count];i++){
        NSString *tempString = [tempStopTimesDataArray objectAtIndex:i];
        NSArray *tempArray = [tempString componentsSeparatedByString:@","];
        if([tempArray count] >= 8){
            [arrayTripIds addObject:[tempArray objectAtIndex:0]];
            [arrayArrivalTime addObject:[tempArray objectAtIndex:1]];
            [arrayDepartureTime addObject:[tempArray objectAtIndex:2]];
            [arrayStopIds addObject:[tempArray objectAtIndex:3]];
            [arrayStopSequences addObject:[tempArray objectAtIndex:4]];
            [arrayPickUpTypes addObject:[tempArray objectAtIndex:5]];
            [arrayDropOfTypes addObject:[tempArray objectAtIndex:6]];
            [arrayShapeDistTravelled addObject:[tempArray objectAtIndex:7]];
        }
    }
    for (int i=0;i<[arrayTripIds count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayTripIds objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayTripIds replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayArrivalTime count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayArrivalTime objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayArrivalTime replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayDepartureTime count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayDepartureTime objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayDepartureTime replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayStopIds count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayStopIds objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayStopIds replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayStopSequences count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayStopSequences objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayStopSequences replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayPickUpTypes count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayPickUpTypes objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayPickUpTypes replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayDropOfTypes count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayDropOfTypes objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayDropOfTypes replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayShapeDistTravelled count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayShapeDistTravelled objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayShapeDistTravelled replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    
    NSMutableArray *arrayServiceIds = [[NSMutableArray alloc] init];
    NSMutableArray *arrayMonday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayTuesday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayWednesday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayThursday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayFriday = [[NSMutableArray alloc] init];
    NSMutableArray *arraySaturday = [[NSMutableArray alloc] init];
    NSMutableArray *arraySunday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStartDate = [[NSMutableArray alloc] init];
    NSMutableArray *arrayEndDate = [[NSMutableArray alloc] init];
    
    // Parsing Data From calendar.txt File
    NSString *strCalendarFilePath = [[NSBundle mainBundle] pathForResource:@"calendar" ofType:@"txt"];
    NSString *strCalendarFileContent = [NSString stringWithContentsOfFile:strCalendarFilePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *tempCalendarDataArray = [strCalendarFileContent componentsSeparatedByString:@"\n"];
    for(int i=1;i<[tempCalendarDataArray count];i++){
        NSString *tempString = [tempCalendarDataArray objectAtIndex:i];
        NSArray *tempArray = [tempString componentsSeparatedByString:@","];
        if([tempArray count] >= 10){
            [arrayServiceIds addObject:[tempArray objectAtIndex:0]];
            [arrayMonday addObject:[tempArray objectAtIndex:1]];
            [arrayTuesday addObject:[tempArray objectAtIndex:2]];
            [arrayWednesday addObject:[tempArray objectAtIndex:3]];
            [arrayThursday addObject:[tempArray objectAtIndex:4]];
            [arrayFriday addObject:[tempArray objectAtIndex:5]];
            [arraySaturday addObject:[tempArray objectAtIndex:6]];
            [arraySunday addObject:[tempArray objectAtIndex:7]];
            [arrayStartDate addObject:[tempArray objectAtIndex:8]];
            [arrayEndDate addObject:[tempArray objectAtIndex:9]];
        }
    }
    for (int i=0;i<[arrayServiceIds count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayServiceIds objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayServiceIds replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayMonday count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayMonday objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayMonday replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayTuesday count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayTuesday objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayTuesday replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayWednesday count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayWednesday objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayWednesday replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayThursday count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayThursday objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayThursday replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayFriday count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayFriday objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayFriday replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arraySaturday count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arraySaturday objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arraySaturday replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arraySunday count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arraySunday objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arraySunday replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayStartDate count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayStartDate objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayStartDate replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayEndDate count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayEndDate objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayEndDate replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    
    NSMutableArray *arrayStopId = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopLat = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopLong = [[NSMutableArray alloc] init];
    NSMutableArray *arrayZoneId = [[NSMutableArray alloc] init];
    
    // Parsing Data From stops.txt File
    NSString *strStopsFilePath = [[NSBundle mainBundle] pathForResource:@"stops" ofType:@"txt"];
    NSString *strStopsFileContent = [NSString stringWithContentsOfFile:strStopsFilePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *tempStopsDataArray = [strStopsFileContent componentsSeparatedByString:@"\n"];
    for(int i=1;i<[tempStopsDataArray count];i++){
        NSString *tempString = [tempStopsDataArray objectAtIndex:i];
        NSArray *tempArray = [tempString componentsSeparatedByString:@","];
        if([tempArray count] >= 6){
            [arrayStopId addObject:[tempArray objectAtIndex:0]];
            [arrayStopName addObject:[tempArray objectAtIndex:1]];
            [arrayStopLat addObject:[tempArray objectAtIndex:4]];
            [arrayStopLong addObject:[tempArray objectAtIndex:5]];
            [arrayZoneId addObject:[tempArray objectAtIndex:6]];
        }
    }
    for (int i=0;i<[arrayStopId count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayStopId objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayStopId replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayStopName count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayStopName objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayStopName replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayStopLat count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayStopLat objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayStopLat replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayStopLong count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayStopLong objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayStopLong replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayZoneId count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayZoneId objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayZoneId replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    
    NSMutableArray *arrayTripID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    
    // Parsing Data From trips.txt File
    NSString *strTripsFilePath = [[NSBundle mainBundle] pathForResource:@"trips" ofType:@"txt"];
    NSString *strTripsFileContent = [NSString stringWithContentsOfFile:strTripsFilePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *tempTripsDataArray = [strTripsFileContent componentsSeparatedByString:@"\n"];
    for(int i=1;i<[tempTripsDataArray count];i++){
        NSString *tempString = [tempTripsDataArray objectAtIndex:i];
        NSArray *tempArray = [tempString componentsSeparatedByString:@","];
        if([tempArray count] >= 3){
            [arrayTripID addObject:[tempArray objectAtIndex:0]];
            [arrayRouteID addObject:[tempArray objectAtIndex:1]];
            [arrayServiceID addObject:[tempArray objectAtIndex:2]];
        }
    }
    for (int i=0;i<[arrayTripID count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayTripID objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayTripID replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayRouteID count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayRouteID objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayRouteID replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    for (int i=0;i<[arrayServiceID count];i++){
        for(int j=0;j<2;j++){
            NSString *strTemp = [arrayServiceID objectAtIndex:i];
            if ([strTemp rangeOfString:@"\"" options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSRange range = [strTemp rangeOfString:@"\""];
                NSMutableString *strMutableRawAddress =  [[NSMutableString alloc] initWithString:strTemp];
                [strMutableRawAddress deleteCharactersInRange:range];
                [arrayServiceID replaceObjectAtIndex:i withObject:strMutableRawAddress];
            }
        }
    }
    PlanStore *store = [nc_AppDelegate sharedInstance].planStore;
    // Change tripDate if required to test other date.
    NSDate *tripDate = [NSDate date];
    int maxDistance = (int)(1.5*1609.544);
    for(int st1 = 0 ; st1 < [arrayStopIds count];st1++){
        PlanRequestParameters* parameters = [[PlanRequestParameters alloc] init];
        NSString *strDepartureTime = [arrayDepartureTime objectAtIndex:st1];
        NSArray *arrayDepartureTimeComponents = [strDepartureTime componentsSeparatedByString:@":"];
        NSDate *finalTripDate = nil;
        if([arrayDepartureTimeComponents count] > 0){
            int hours = [[arrayDepartureTimeComponents objectAtIndex:0] intValue];
            int minutes = [[arrayDepartureTimeComponents objectAtIndex:1] intValue];
            int seconds = [[arrayDepartureTimeComponents objectAtIndex:2] intValue];
            if(hours > 23){
                if(hours > 0){
                    finalTripDate = [tripDate dateByAddingTimeInterval:24*60*60];
                }
                else if(minutes > 5){
                    finalTripDate = [tripDate dateByAddingTimeInterval:24*60*60];
                }
                hours = hours - 24;
            }
            strDepartureTime = [NSString stringWithFormat:@"%d:%d:%d",hours,minutes,seconds];
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
        NSDate *dates = [formatter dateFromString:strDepartureTime];
        NSDate *dateBeforeFiveSeconds = [dates dateByAddingTimeInterval:-300];
        NSDate *timesOnly = timeOnlyFromDate(dateBeforeFiveSeconds);
        NSDate *datesOnly;
        if(finalTripDate){
            datesOnly = dateOnlyFromDate(finalTripDate);
        }
        else{
            datesOnly = dateOnlyFromDate(tripDate);
        }
        NSDate *finalDate = addDateOnlyWithTimeOnly(datesOnly, timesOnly);
        parameters.originalTripDate = finalDate;
        parameters.thisRequestTripDate = finalDate;
        parameters.departOrArrive = DEPART;
        parameters.maxWalkDistance = maxDistance;
        parameters.planDestination = PLAN_DESTINATION_TO_FROM_VC;
        NSString *strLatitudeTo;
        NSString *strLatitudeFrom;
        NSString *strLongitudeTo;
        NSString *strLongitudeFrom;
        for (int nlatlng = 0; nlatlng < [arrayStopId count]; nlatlng++) {
            if ([[arrayStopId objectAtIndex:nlatlng] isEqualToString:[arrayStopIds objectAtIndex:st1]]) {
                strLatitudeTo = [arrayStopLat objectAtIndex:nlatlng];
                strLongitudeTo = [arrayStopLong objectAtIndex:nlatlng];
                if([arrayStopId count]>nlatlng+1){
                    strLatitudeFrom = [arrayStopLat objectAtIndex:nlatlng+1];
                    strLongitudeFrom = [arrayStopLong objectAtIndex:nlatlng+1];
                }
            }
        }
        for (int nlatlngFrom = 0; nlatlngFrom < [arrayStopId count]; nlatlngFrom++) {
            if ([arrayStopIds count]>st1+1 && [[arrayStopId objectAtIndex:nlatlngFrom] isEqualToString:[arrayStopIds objectAtIndex:st1+1]]) {
                strLatitudeFrom = [arrayStopLat objectAtIndex:nlatlngFrom];
                strLongitudeFrom = [arrayStopLong objectAtIndex:nlatlngFrom];
            }
        }
        // Get Service Id From Trip ID
        NSString *strTripID = [arrayTripIds objectAtIndex:st1];
        if([arrayTripIds count] > st1+1 && [[arrayTripIds objectAtIndex:st1]isEqualToString:[arrayTripIds objectAtIndex:st1+1]]){
            NSString *strSerViceID;
            for(int sid =0;sid<[arrayServiceID count];sid++){
                if([strTripID isEqualToString:[arrayTripID objectAtIndex:sid]]){
                    strSerViceID = [arrayServiceID objectAtIndex:sid];
                    break;
                }
            }
            // Get The Service End Date And Array of day indicating 0 or 1.
            NSString *strEndDate;
            NSArray *dayArray;
            for(int sid1 = 0;sid1 < [arrayServiceIds count];sid1++){
                if([strSerViceID isEqualToString:[arrayServiceIds objectAtIndex:sid1]]){
                    strEndDate = [arrayEndDate objectAtIndex:sid1];
                    dayArray = [NSArray arrayWithObjects:[arraySunday objectAtIndex:sid1],[arrayMonday objectAtIndex:sid1],[arrayTuesday objectAtIndex:sid1],[arrayWednesday objectAtIndex:sid1],[arrayThursday objectAtIndex:sid1],[arrayFriday objectAtIndex:sid1],[arraySaturday objectAtIndex:sid1], nil];
                    break;
                }
            }
            NSDate *date = [NSDate date];
            NSInteger dayOfWeek = dayOfWeekFromDate(date)-1;
            NSDate* dateOnly = dateOnlyFromDate(date);
            NSDateFormatter *dateFormatters = [[NSDateFormatter alloc] init];
            [dateFormatters setDateFormat:@"YYYMMdd"];
            // If service is not expire and service is enabled on that day then we will request TP For Plan.
            NSString* strDateOnly = [dateFormatters stringFromDate:dateOnly];
            if (strEndDate && [strEndDate compare:strDateOnly] == NSOrderedDescending) {
                if([[dayArray objectAtIndex:dayOfWeek] isEqualToString:@"1"]){
                    Location *fromLocation = [locations newEmptyLocation];
                    fromLocation.formattedAddress = [arrayStopIds objectAtIndex:st1];
                    fromLocation.lat = [NSNumber numberWithDouble:[strLatitudeTo doubleValue]];
                    fromLocation.lng = [NSNumber numberWithDouble:[strLongitudeTo doubleValue]];
                    
                    Location *toLocation = [locations newEmptyLocation];
                    if([arrayStopIds count] > st1+1){
                        toLocation.formattedAddress = [arrayStopIds objectAtIndex:st1+1];
                        toLocation.lat = [NSNumber numberWithDouble:[strLatitudeFrom doubleValue]];
                        toLocation.lng = [NSNumber numberWithDouble:[strLongitudeFrom doubleValue]];
                    }
                    parameters.fromLocation = fromLocation;
                    parameters.toLocation = toLocation;
                    NSString *strFinalDate = [dateFormatter stringFromDate:finalDate];
                    strFinalDate = [strFinalDate stringByReplacingOccurrencesOfString:@"," withString:@""];
                    [nc_AppDelegate sharedInstance].expectedRequestDate = [arrayDepartureTime objectAtIndex:st1];
                    [[nc_AppDelegate sharedInstance].testLogMutableString appendFormat:@"%@,%@,%@,%@,",fromLocation.formattedAddress,toLocation.formattedAddress,strFinalDate,strTripID];
                    [store requestPlanFromOtpWithParameters:parameters];
                    [self someMethodToWaitForResult];
                    [self planTestWithComparingTime];
                }
            }
        }
    }
}

@end
