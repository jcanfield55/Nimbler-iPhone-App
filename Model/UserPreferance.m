//
//  UserPreferance.m
//  Nimbler
//
//  Created by JaY Kumbhani on 7/2/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "UserPreferance.h"
#import "nc_AppDelegate.h"
#import "UtilityFunctions.h"

// Function to translate from settings bool values to strings used to send to server
NSString* tpBoolToStr(BOOL boolValue)
{
    return (boolValue ? @"1" : @"2");
}

// Function to translate from settings string values from server to boolean
BOOL tpStrToBool(NSString* stringValue)
{
    if ([stringValue isEqualToString:@"1"]) {
        return true;
    }
    return false;
}

@interface UserPreferance() {
    NSDate* dateOfLastSaveToServerAttempt;
}
// The following two dates determine whether settings need to be saved to the server.
// If dateOfLastUserPrefChange is more recent than dateOfLastSuccessfulSaveToServer, then another save needs to be done
@property(nonatomic, strong) NSDate* dateOfLastUserPrefChange;
@property(nonatomic, strong) NSDate* dateOfLastSuccessfulSaveToServer;

-(void)recomputeBikeTriangle;
-(void)markChanges;  // Marks that changes have been made (by updating dateOfLastUserPrefChange)
@end


@implementation UserPreferance

@synthesize pushEnable;
@synthesize pushNotificationThreshold;
@synthesize walkDistance;
@synthesize sfMuniAdvisories;
@synthesize bartAdvisories;
@synthesize acTransitAdvisories;
@synthesize caltrainAdvisories;
@synthesize urgentNotificationSound;
@synthesize standardNotificationSound;
@synthesize notificationMorning;
@synthesize notificationMidday;
@synthesize notificationEvening;
@synthesize notificationNight;
@synthesize notificationWeekend;
@synthesize transitMode;
@synthesize bikeDistance;
@synthesize fastVsFlat;
@synthesize fastVsSafe;
@synthesize bikeTriangleFlat;
@synthesize bikeTriangleQuick;
@synthesize bikeTriangleBikeFriendly;
@synthesize dateOfLastUserPrefChange;
@synthesize dateOfLastSuccessfulSaveToServer;


static UserPreferance* userPrefs;

// Return the singleton object.  Sets to default values if no value already saved
// Will save to server if new default values created
+(UserPreferance *)userPreferance
{
    if (!userPrefs) {  // if no static storage of preferences
        // Try to retrieve preferences from permanent storage.  Use defaults if no value in permanent storage
        userPrefs = [[UserPreferance alloc] init];
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        bool saveNeeded = false;
        
        NSNumber* pushEnableTemp = [prefs objectForKey:PREFS_IS_PUSH_ENABLE];
        if (pushEnableTemp) {
            userPrefs.pushEnable = pushEnableTemp.boolValue;
        } else {
            userPrefs.pushEnable = PREFS_DEFAULT_IS_PUSH_ENABLE;
            saveNeeded = true;
        }
        
        NSNumber* pushNotifTemp = [prefs objectForKey:PREFS_PUSH_NOTIFICATION_THRESHOLD];
        if (pushNotifTemp) {
            userPrefs.pushNotificationThreshold = pushNotifTemp.intValue;
        } else {
            userPrefs.pushNotificationThreshold = PREFS_DEFAULT_PUSH_NOTIFICATION_THRESHOLD;
            saveNeeded = true;
        }
        
        NSNumber* walkDistTemp = [prefs objectForKey:PREFS_MAX_WALK_DISTANCE];
        if (walkDistTemp) {
            userPrefs.walkDistance = walkDistTemp.doubleValue;
        } else {
            userPrefs.walkDistance = MAX_WALK_DISTANCE_DEFAULT_VALUE;
            saveNeeded = true;
        }
        
        NSString* sfMuniTemp = [prefs objectForKey:ENABLE_SFMUNI_ADV];
        if (sfMuniTemp) {
            userPrefs.sfMuniAdvisories = tpStrToBool(sfMuniTemp);
        } else {
            userPrefs.sfMuniAdvisories = ENABLE_SFMUNI_ADV_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* bartTemp = [prefs objectForKey:ENABLE_BART_ADV];
        if (bartTemp) {
            userPrefs.bartAdvisories = tpStrToBool(bartTemp);
        } else {
            userPrefs.bartAdvisories = ENABLE_BART_ADV_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* acTransitTemp = [prefs objectForKey:ENABLE_ACTRANSIT_ADV];
        if (acTransitTemp) {
            userPrefs.acTransitAdvisories = tpStrToBool(acTransitTemp);
        } else {
            userPrefs.acTransitAdvisories = ENABLE_ACTRANSIT_ADV_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* caltrainTemp = [prefs objectForKey:ENABLE_CALTRAIN_ADV];
        if (caltrainTemp) {
            userPrefs.caltrainAdvisories = tpStrToBool(caltrainTemp);
        } else {
            userPrefs.caltrainAdvisories = ENABLE_CALTRAIN_ADV_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* urgentNotifyTemp = [prefs objectForKey:ENABLE_URGENTNOTIFICATION_SOUND];
        if (urgentNotifyTemp) {
            userPrefs.urgentNotificationSound = tpStrToBool(urgentNotifyTemp);
        } else {
            userPrefs.urgentNotificationSound = ENABLE_URGENTNOTIF_SOUND_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* standardNotifyTemp = [prefs objectForKey:ENABLE_STANDARDNOTIFICATION_SOUND];
        if (standardNotifyTemp) {
            userPrefs.standardNotificationSound = tpStrToBool(standardNotifyTemp);
        } else {
            userPrefs.standardNotificationSound = ENABLE_STANDARDNOTIF_SOUND_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* notifyMorning = [prefs objectForKey:NOTIF_TIMING_MORNING];
        if (notifyMorning) {
            userPrefs.notificationMorning = tpStrToBool(notifyMorning);
        } else {
            userPrefs.notificationMorning = NOTIF_TIMING_MORNING_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* notifyMidday = [prefs objectForKey:NOTIF_TIMING_MIDDAY];
        if (notifyMidday) {
            userPrefs.notificationMidday = tpStrToBool(notifyMidday);
        } else {
            userPrefs.notificationMidday = NOTIF_TIMING_MIDDAY_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* notifyEvening = [prefs objectForKey:NOTIF_TIMING_EVENING];
        if (notifyEvening) {
            userPrefs.notificationEvening = tpStrToBool(notifyEvening);
        } else {
            userPrefs.notificationEvening = NOTIF_TIMING_EVENING_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* notifyNight = [prefs objectForKey:NOTIF_TIMING_NIGHT];
        if (notifyNight) {
            userPrefs.notificationNight = tpStrToBool(notifyNight);
        } else {
            userPrefs.notificationNight = NOTIF_TIMING_NIGHT_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* notifyWeekend = [prefs objectForKey:NOTIF_TIMING_WEEKEND];
        if (notifyWeekend) {
            userPrefs.notificationWeekend = tpStrToBool(notifyWeekend);
        } else {
            userPrefs.notificationWeekend = NOTIF_TIMING_WEEKEND_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* transitModeTemp = [prefs objectForKey:TRANSIT_MODE_SELECTED];
        if (transitModeTemp) {
            userPrefs.transitMode = transitModeTemp.integerValue;
        } else {
            userPrefs.transitMode = TRANSIT_MODE_DEFAULT;
            saveNeeded = true;
        }
        
        NSString* bikeDistanceTemp = [prefs objectForKey:PREFS_MAX_BIKE_DISTANCE];
        if (bikeDistanceTemp) {
            userPrefs.bikeDistance = bikeDistanceTemp.doubleValue;
        } else {
            userPrefs.bikeDistance = MAX_BIKE_DISTANCE_DEFAULT_VALUE;
            saveNeeded = true;
        }
        
        NSString* fastVsSafeTemp = [prefs objectForKey:PREFS_BIKE_FAST_VS_SAFE];
        if (fastVsSafeTemp) {
            userPrefs.fastVsSafe = fastVsSafeTemp.doubleValue;
        } else {
            userPrefs.fastVsSafe = BIKE_PREFERENCE_DEFAULT_VALUE;
            saveNeeded = true;
        }
        
        NSString* fastVsFlatTemp = [prefs objectForKey:PREFS_BIKE_FAST_VS_FLAT];
        if (fastVsFlatTemp) {
            userPrefs.fastVsFlat = fastVsFlatTemp.doubleValue;
        } else {
            userPrefs.fastVsFlat = BIKE_PREFERENCE_DEFAULT_VALUE;
            saveNeeded = true;
        }
        [userPrefs recomputeBikeTriangle]; // Compute bike triangle variables from fastVsFlat and fastVsSafe
        
        userPrefs.dateOfLastSuccessfulSaveToServer = [prefs objectForKey:PREFS_DATE_LAST_SUCCESSFUL_SAVE];
        userPrefs.dateOfLastUserPrefChange = [prefs objectForKey:PREFS_DATE_LAST_CHANGE];

        if (saveNeeded) {
            [userPrefs saveUpdates];
            [userPrefs saveToServer];
        }
    }
    return userPrefs;
}

-(void)recomputeBikeTriangle
{
    double denominator = 0.5*self.fastVsSafe * 0.5*self.fastVsFlat + 1;
    bikeTriangleFlat = fastVsFlat / denominator;
    bikeTriangleBikeFriendly = fastVsSafe / denominator;
    bikeTriangleQuick = (2 - fastVsFlat - fastVsSafe)/(2 * denominator);
}

// Saves changes to permanent storage on device
-(void)saveUpdates
{
    /* Commenting this out for now, since the changes are currently being made in the setter methods
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:dateOfLastUserPrefChange forKey:PREFS_DATE_LAST_CHANGE];
    [prefs setObject:dateOfLastSuccessfulSaveToServer forKey:PREFS_DATE_LAST_SUCCESSFUL_SAVE];
    [prefs setObject:[NSNumber numberWithBool:pushEnable] forKey:PREFS_IS_PUSH_ENABLE];
    [prefs setObject:[NSNumber numberWithInt:pushNotificationThreshold] forKey:PREFS_PUSH_NOTIFICATION_THRESHOLD];
    [prefs setObject:[NSNumber numberWithFloat:walkDistance] forKey:PREFS_MAX_WALK_DISTANCE];
    [prefs setObject:tpBoolToStr(sfMuniAdvisories) forKey:ENABLE_SFMUNI_ADV];
    [prefs setObject:tpBoolToStr(bartAdvisories) forKey:ENABLE_BART_ADV];
    [prefs setObject:tpBoolToStr(acTransitAdvisories) forKey:ENABLE_ACTRANSIT_ADV];
    [prefs setObject:tpBoolToStr(caltrainAdvisories) forKey:ENABLE_CALTRAIN_ADV];
    [prefs setObject:tpBoolToStr(urgentNotificationSound) forKey:ENABLE_URGENTNOTIFICATION_SOUND];
    [prefs setObject:tpBoolToStr(standardNotificationSound) forKey:ENABLE_STANDARDNOTIFICATION_SOUND];
    [prefs setObject:tpBoolToStr(notificationMorning) forKey:NOTIF_TIMING_MORNING];
    [prefs setObject:tpBoolToStr(notificationMidday) forKey:NOTIF_TIMING_MIDDAY];
    [prefs setObject:tpBoolToStr(notificationEvening) forKey:NOTIF_TIMING_EVENING];
    [prefs setObject:tpBoolToStr(notificationNight) forKey:NOTIF_TIMING_NIGHT];
    [prefs setObject:tpBoolToStr(notificationWeekend) forKey:NOTIF_TIMING_WEEKEND];
    [prefs setObject:[NSNumber numberWithInt:transitMode] forKey:TRANSIT_MODE_SELECTED];
    [prefs setObject:[NSNumber numberWithDouble:bikeDistance] forKey:PREFS_MAX_BIKE_DISTANCE];
    [prefs setObject:[NSNumber numberWithDouble:fastVsFlat] forKey:PREFS_BIKE_FAST_VS_FLAT];
    [prefs setObject:[NSNumber numberWithDouble:fastVsSafe] forKey:PREFS_BIKE_FAST_VS_SAFE];
    [prefs synchronize];
     */
}


// Returns true if there are changes that still need to be save to server
-(BOOL)isSaveToServerNeeded
{
    if (!dateOfLastSuccessfulSaveToServer) {
        return TRUE;
    }
    else if (!dateOfLastUserPrefChange) {
        return FALSE;
    } 
    return ([[self dateOfLastSuccessfulSaveToServer] compare:self.dateOfLastUserPrefChange] == NSOrderedAscending);
}

// Marks that changes have been made (by updating dateOfLastUserPrefChange)
-(void)markChanges
{
    dateOfLastUserPrefChange = [NSDate date];
}


//
// Save changes to server using Restkit
//
-(void)saveToServer 
{
    @try {
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        
        int alertCount = (pushEnable ? pushNotificationThreshold : PUSH_NOTIFY_OFF); // -1 if push notification is off
        dateOfLastSaveToServerAttempt = [NSDate date];
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                                DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                ALERT_COUNT,[NSNumber numberWithInt:alertCount],
                                DEVICE_TOKEN, [prefs objectForKey:DEVICE_TOKEN],
                                MAXIMUM_WALK_DISTANCE,[prefs objectForKey:PREFS_MAX_WALK_DISTANCE],
                                ENABLE_URGENTNOTIFICATION_SOUND,[prefs objectForKey:ENABLE_URGENTNOTIFICATION_SOUND],
                                ENABLE_STANDARDNOTIFICATION_SOUND,[prefs objectForKey:ENABLE_STANDARDNOTIFICATION_SOUND],
                                ENABLE_SFMUNI_ADV,[prefs objectForKey:ENABLE_SFMUNI_ADV],
                                ENABLE_BART_ADV,[prefs objectForKey:ENABLE_BART_ADV],
                                ENABLE_ACTRANSIT_ADV,[prefs objectForKey:ENABLE_ACTRANSIT_ADV],
                                ENABLE_CALTRAIN_ADV,[prefs objectForKey:ENABLE_CALTRAIN_ADV],
                                NOTIF_TIMING_MORNING,[prefs objectForKey:NOTIF_TIMING_MORNING],
                                NOTIF_TIMING_MIDDAY,[prefs objectForKey:NOTIF_TIMING_MIDDAY],
                                NOTIF_TIMING_EVENING,[prefs objectForKey:NOTIF_TIMING_EVENING],
                                NOTIF_TIMING_NIGHT,[prefs objectForKey:NOTIF_TIMING_NIGHT],
                                NOTIF_TIMING_WEEKEND,[prefs objectForKey:NOTIF_TIMING_WEEKEND],
                                APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],
                                
                                // TODO -- add bicycle settings saving as needed
                                
                                nil];
        NSString *updateURL = [UPDATE_SETTING_REQ appendQueryParams:params];
        NIMLOG_EVENT1(@" updateSettingsServerURL: %@", updateURL);
        [[RKClient sharedClient] get:updateURL delegate:self];

    }
    @catch (NSException *exception) {
        logException(@"UserPreferance-->saveToServer", @"", exception);
    }
}

// Callback from saving settings to server
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    RKJSONParserJSONKit* rkDataParser = [RKJSONParserJSONKit new];
    @try {
        if ([request isGET]) {
            id  res = [rkDataParser objectFromString:[response bodyAsString] error:nil];
            NSNumber *respCode = [(NSDictionary*)res objectForKey:RESPONSE_CODE];
            if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                self.dateOfLastSuccessfulSaveToServer = dateOfLastSaveToServerAttempt;
            }
            NIMLOG_EVENT1(@"response for userUpdateSettings:  %@", [response bodyAsString]);
        }
    }  @catch (NSException *exception) {
        logException(@"UserPrefarance->didLoadResponse", @"while getting unique IDs from TP Server response", exception);
    }
}

//
// Setters for each user preference property.  Saves in memory and to [NSUserDefaults standardUserDefaults]
//


-(void) setDateOfLastUserPrefChange:(NSDate *)dateOfLastUserPrefChng
{
    dateOfLastUserPrefChange = dateOfLastUserPrefChng;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:dateOfLastUserPrefChange forKey:PREFS_DATE_LAST_CHANGE];
    [prefs synchronize];
}

-(void) setDateOfLastSuccessfulSaveToServer:(NSDate *)dateOfLastSuccessfulSaveToSrv
{
    dateOfLastSuccessfulSaveToServer = dateOfLastSuccessfulSaveToSrv;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:dateOfLastSuccessfulSaveToServer forKey:PREFS_DATE_LAST_SUCCESSFUL_SAVE];
    [prefs synchronize];
}

-(void) setPushEnable:(BOOL)pushEn
{
    pushEnable = pushEn;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:pushEnable] forKey:PREFS_IS_PUSH_ENABLE];
    [prefs synchronize];
    [self markChanges];
}


-(void) setPushNotificationThreshold:(int)pushNotificationThr
{
    pushNotificationThreshold = pushNotificationThr;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInt:pushNotificationThreshold] forKey:PREFS_PUSH_NOTIFICATION_THRESHOLD];
    [prefs synchronize];
    [self markChanges];
}

-(void) setWalkDistance:(double)walkDist
{
    walkDistance = walkDist;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithFloat:walkDistance] forKey:PREFS_MAX_WALK_DISTANCE];
    [prefs synchronize];
    [self markChanges];
}

-(void) setSfMuniAdvisories:(BOOL)sfMuniAdv
{
    sfMuniAdvisories = sfMuniAdv;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(sfMuniAdvisories) forKey:ENABLE_SFMUNI_ADV];
    [prefs synchronize];
    [self markChanges];
}


-(void) setBartAdvisories:(BOOL)bartAdv
{
    bartAdvisories = bartAdv;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(bartAdvisories) forKey:ENABLE_BART_ADV];
    [prefs synchronize];
    [self markChanges];
}

-(void) setAcTransitAdvisories:(BOOL)acTransitAdv
{
    acTransitAdvisories = acTransitAdv;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(acTransitAdvisories) forKey:ENABLE_ACTRANSIT_ADV];
    [prefs synchronize];
    [self markChanges];
}

-(void) setCaltrainAdvisories:(BOOL)caltrainAdv
{
    caltrainAdvisories = caltrainAdv;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(caltrainAdvisories) forKey:ENABLE_CALTRAIN_ADV];
    [prefs synchronize];
    [self markChanges];
}

-(void) setUrgentNotificationSound:(BOOL)urgentNotificationSnd
{
    urgentNotificationSound = urgentNotificationSnd;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(urgentNotificationSound) forKey:ENABLE_URGENTNOTIFICATION_SOUND];
    [prefs synchronize];
    [self markChanges];
}


-(void) setStandardNotificationSound:(BOOL)standardNotificationSnd
{
    standardNotificationSound = standardNotificationSnd;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(standardNotificationSound) forKey:ENABLE_STANDARDNOTIFICATION_SOUND];
    [prefs synchronize];
    [self markChanges];
}

-(void) setNotificationMorning:(BOOL)notifyMrn
{
    notificationMorning = notifyMrn;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(notificationMorning) forKey:NOTIF_TIMING_MORNING];
    [prefs synchronize];
    [self markChanges];
}

-(void) setNotificationMidday:(BOOL)notifyMidday
{
    notificationMidday = notifyMidday;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(notificationMidday) forKey:NOTIF_TIMING_MIDDAY];
    [prefs synchronize];
    [self markChanges];
}

-(void) setNotificationEvening:(BOOL)notifyEvening
{
    notificationEvening = notifyEvening;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(notificationEvening) forKey:NOTIF_TIMING_EVENING];
    [prefs synchronize];
    [self markChanges];
}

-(void) setNotificationNight:(BOOL)notifyNight
{
    notificationNight = notifyNight;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(notificationNight) forKey:NOTIF_TIMING_NIGHT];
    [prefs synchronize];
    [self markChanges];
}

-(void) setNotificationWeekend:(BOOL)notifyWeekend
{
    notificationWeekend = notifyWeekend;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tpBoolToStr(notificationWeekend) forKey:NOTIF_TIMING_WEEKEND];
    [prefs synchronize];
    [self markChanges];
}

-(void) setTransitMode:(int)transitModeTemp
{
    transitMode = transitModeTemp;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInt:transitMode] forKey:TRANSIT_MODE_SELECTED];
    [prefs synchronize];
    [self markChanges];
}

-(void) setBikeDistance:(double)bikeDistanceTemp
{
    bikeDistance = bikeDistanceTemp;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithDouble:bikeDistance] forKey:PREFS_MAX_BIKE_DISTANCE];
    [prefs synchronize];
    [self markChanges];
}

-(void) setFastVsFlat:(double)fastVsFlatTemp
{
    fastVsFlat = fastVsFlatTemp;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithDouble:fastVsFlat] forKey:PREFS_BIKE_FAST_VS_FLAT];
    [prefs synchronize];
    [self recomputeBikeTriangle];
    [self markChanges];
}

-(void) setFastVsSafe:(double)fastVsSafeTemp
{
    fastVsSafe = fastVsSafeTemp;
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithDouble:fastVsSafe] forKey:PREFS_BIKE_FAST_VS_SAFE];
    [prefs synchronize];
    [self recomputeBikeTriangle];
    [self markChanges];
}

@end
