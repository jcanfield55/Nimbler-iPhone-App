//
//  SettingViewCustomCell.m
//  Nimbler Caltrain
//
//  Created by macmini on 20/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingViewCustomCell.h"

@implementation SettingViewCustomCell

@synthesize lblSFMuniAdvisories;
@synthesize switchSFMuniAdvisories;
@synthesize lblBartAdvisories;
@synthesize switchBartAdvisories;
@synthesize lblACTransitAdvisories;
@synthesize switchACTransitAdvisories;
@synthesize lblCaltrainAdvisories;
@synthesize switchCaltrainAdvisories;

@synthesize lblPushNotification;
@synthesize switchPushNotification;
@synthesize lblPushNotificationFrequency;
@synthesize sliderPushNotificationFrequency;
@synthesize lblNotificationSound;
@synthesize lblUrgentNotifications;
@synthesize switchUrgentNotifications;
@synthesize lblStandardNotifications;
@synthesize switchStandardNotifications;
@synthesize lblNotificationTiming;
@synthesize lblWeekDayMorning;
@synthesize lblWeekDayMidDay;
@synthesize lblWeekDayEveningPeak;
@synthesize lblWeekDayNight;
@synthesize lblWeekends;

@synthesize lblTransitOnly;
@synthesize lblBikeOnly;
@synthesize lblBikeAndTransit;

@synthesize lblMaximumWalkDistance;
@synthesize sliderMaximumWalkDistance;

@synthesize lblMaximumBikeDistance;
@synthesize sliderMaximumBikeDistance;
@synthesize lblPreferenceFastVsSafe;
@synthesize switchPreferenceFastVsSafe;
@synthesize lblPreferenceFastVsFlat;
@synthesize switchPreferenceFastVsFlat;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if(!lblSFMuniAdvisories){
            lblSFMuniAdvisories = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblSFMuniAdvisories setBackgroundColor:[UIColor clearColor]];
            [lblSFMuniAdvisories setTextColor:[UIColor lightGrayColor]];
            [lblSFMuniAdvisories setTextAlignment:UITextAlignmentLeft];
            [lblSFMuniAdvisories setText:SFMUNI_ADVISORIES];
            [lblSFMuniAdvisories setHidden:YES];
            [self addSubview:lblSFMuniAdvisories];
        }
        if(!switchSFMuniAdvisories){
            switchSFMuniAdvisories = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchACTransitAdvisories setOn:NO];
            [self addSubview:switchSFMuniAdvisories];
        }
        if(!lblBartAdvisories){
            lblBartAdvisories = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblBartAdvisories setBackgroundColor:[UIColor clearColor]];
            [lblBartAdvisories setTextColor:[UIColor lightGrayColor]];
            [lblBartAdvisories setTextAlignment:UITextAlignmentLeft];
            [lblBartAdvisories setText:BART_ADVISORIES];
            [self addSubview:lblBartAdvisories];
        }
        if(!switchBartAdvisories){
            switchBartAdvisories = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchBartAdvisories setOn:NO];
            [self addSubview:switchBartAdvisories];
        }
        if(!lblACTransitAdvisories){
            lblACTransitAdvisories = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblACTransitAdvisories setBackgroundColor:[UIColor clearColor]];
            [lblACTransitAdvisories setTextColor:[UIColor lightGrayColor]];
            [lblACTransitAdvisories setTextAlignment:UITextAlignmentLeft];
            [lblACTransitAdvisories setText:ACTRANSIT_ADVISORIES];
            [self addSubview:lblACTransitAdvisories];
        }
        if(!switchACTransitAdvisories){
            switchACTransitAdvisories = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchACTransitAdvisories setOn:NO];
            [self addSubview:switchACTransitAdvisories];
        }
        if(!lblCaltrainAdvisories){
            lblCaltrainAdvisories = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblCaltrainAdvisories setBackgroundColor:[UIColor clearColor]];
            [lblCaltrainAdvisories setTextColor:[UIColor lightGrayColor]];
            [lblCaltrainAdvisories setTextAlignment:UITextAlignmentLeft];
            [lblCaltrainAdvisories setText:CALTRAIN_ADVISORIES];
            [self addSubview:lblCaltrainAdvisories];
        }
        if(!switchCaltrainAdvisories){
            switchCaltrainAdvisories = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchCaltrainAdvisories setOn:NO];
            [self addSubview:switchCaltrainAdvisories];
        }
        
        if(!lblPushNotification){
            lblPushNotification = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblPushNotification setBackgroundColor:[UIColor clearColor]];
            [lblPushNotification setTextColor:[UIColor lightGrayColor]];
            [lblPushNotification setTextAlignment:UITextAlignmentLeft];
            [lblPushNotification setText:PUSH_NOTIFICATION];
            [self addSubview:lblPushNotification];
        }
        if(!switchPushNotification){
            switchPushNotification = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchPushNotification setOn:NO];
            [self addSubview:switchPushNotification];
        }
        
        if(!lblPushNotificationFrequency){
            lblPushNotificationFrequency = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 230, 20)];
            [lblPushNotificationFrequency setBackgroundColor:[UIColor clearColor]];
            [lblPushNotificationFrequency setTextColor:[UIColor lightGrayColor]];
            [lblPushNotificationFrequency setTextAlignment:UITextAlignmentLeft];
            [lblPushNotificationFrequency setText:FREQUENCY_OF_PUSH];
            [self addSubview:lblPushNotificationFrequency];
        }
        if(!sliderPushNotificationFrequency){
            sliderPushNotificationFrequency = [[UISlider alloc] initWithFrame:CGRectMake(240, 15, 70, 30)];
            [self addSubview:sliderPushNotificationFrequency];
        }
        
        if(!lblNotificationSound){
            lblNotificationSound = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblNotificationSound setBackgroundColor:[UIColor clearColor]];
            [lblNotificationSound setTextColor:[UIColor lightGrayColor]];
            [lblNotificationSound setTextAlignment:UITextAlignmentLeft];
            [lblNotificationSound setText:NOTIFICATION_SOUND];
            [self addSubview:lblNotificationSound];
        }
        
        if(!lblUrgentNotifications){
            lblUrgentNotifications = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblUrgentNotifications setBackgroundColor:[UIColor clearColor]];
            [lblUrgentNotifications setTextColor:[UIColor lightGrayColor]];
            [lblUrgentNotifications setTextAlignment:UITextAlignmentLeft];
            [lblUrgentNotifications setText:URGENT_NOTIFICATIONS];
            [self addSubview:lblUrgentNotifications];
        }
        if(!switchUrgentNotifications){
            switchUrgentNotifications = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchUrgentNotifications setOn:NO];
            [self addSubview:switchUrgentNotifications];
        }
        
        if(!lblStandardNotifications){
            lblStandardNotifications = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblStandardNotifications setBackgroundColor:[UIColor clearColor]];
            [lblStandardNotifications setTextColor:[UIColor lightGrayColor]];
            [lblStandardNotifications setTextAlignment:UITextAlignmentLeft];
            [lblStandardNotifications setText:STANDARD_NOTIFICATIONS];
            [self addSubview:lblStandardNotifications];
        }
        if(!switchStandardNotifications){
            switchStandardNotifications = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchStandardNotifications setOn:NO];
            [self addSubview:switchStandardNotifications];
        }

        if(!lblNotificationTiming){
            lblNotificationTiming = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblNotificationTiming setBackgroundColor:[UIColor clearColor]];
            [lblNotificationTiming setTextColor:[UIColor lightGrayColor]];
            [lblNotificationTiming setTextAlignment:UITextAlignmentLeft];
            [lblNotificationTiming setText:NOTIFICATION_TIMING];
            [self addSubview:lblNotificationTiming];
        }
        if(!lblWeekDayMorning){
            lblWeekDayMorning = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblWeekDayMorning setBackgroundColor:[UIColor clearColor]];
            [lblWeekDayMorning setTextColor:[UIColor lightGrayColor]];
            [lblWeekDayMorning setTextAlignment:UITextAlignmentLeft];
            [lblWeekDayMorning setText:WEEKDAY_MORNING];
            [self addSubview:lblWeekDayMorning];
        }
        if(!lblWeekDayMidDay){
            lblWeekDayMidDay = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblWeekDayMidDay setBackgroundColor:[UIColor clearColor]];
            [lblWeekDayMidDay setTextColor:[UIColor lightGrayColor]];
            [lblWeekDayMidDay setTextAlignment:UITextAlignmentLeft];
            [lblWeekDayMidDay setText:WEEKDAY_MIDDAY];
            [self addSubview:lblWeekDayMidDay];
        }
        if(!lblWeekDayEveningPeak){
            lblWeekDayEveningPeak = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblWeekDayEveningPeak setBackgroundColor:[UIColor clearColor]];
            [lblWeekDayEveningPeak setTextColor:[UIColor lightGrayColor]];
            [lblWeekDayEveningPeak setTextAlignment:UITextAlignmentLeft];
            [lblWeekDayEveningPeak setText:WEEKDAY_EVENING_PEAK];
            [self addSubview:lblWeekDayEveningPeak];
        }
        if(!lblWeekDayNight){
            lblWeekDayNight = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblWeekDayNight setBackgroundColor:[UIColor clearColor]];
            [lblWeekDayNight setTextColor:[UIColor lightGrayColor]];
            [lblWeekDayNight setTextAlignment:UITextAlignmentLeft];
            [lblWeekDayNight setText:WEEKDAY_NIGHT];
            [self addSubview:lblWeekDayNight];
        }
        if(!lblWeekends){
            lblWeekends = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblWeekends setBackgroundColor:[UIColor clearColor]];
            [lblWeekends setTextColor:[UIColor lightGrayColor]];
            [lblWeekends setTextAlignment:UITextAlignmentLeft];
            [lblWeekends setText:WEEKENDS];
            [self addSubview:lblWeekends];
        }
        
        if(!lblTransitOnly){
            lblTransitOnly = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblTransitOnly setBackgroundColor:[UIColor clearColor]];
            [lblTransitOnly setTextColor:[UIColor lightGrayColor]];
            [lblTransitOnly setTextAlignment:UITextAlignmentLeft];
            [lblTransitOnly setText:TRANSIT_ONLY];
            [self addSubview:lblTransitOnly];
        }
        if(!lblBikeOnly){
            lblBikeOnly = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblBikeOnly setBackgroundColor:[UIColor clearColor]];
            [lblBikeOnly setTextColor:[UIColor lightGrayColor]];
            [lblBikeOnly setTextAlignment:UITextAlignmentLeft];
            [lblBikeOnly setText:BIKE_ONLY];
            [self addSubview:lblBikeOnly];
        }
    
        if(!lblBikeAndTransit){
            lblBikeAndTransit = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 300, 20)];
            [lblBikeAndTransit setBackgroundColor:[UIColor clearColor]];
            [lblBikeAndTransit setTextColor:[UIColor lightGrayColor]];
            [lblBikeAndTransit setTextAlignment:UITextAlignmentLeft];
            [lblBikeAndTransit setText:BIKE_AND_TRANSIT];
            [self addSubview:lblBikeAndTransit];
        }
        
        
        if(!lblMaximumWalkDistance){
            lblMaximumWalkDistance = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblMaximumWalkDistance setBackgroundColor:[UIColor clearColor]];
            [lblMaximumWalkDistance setTextColor:[UIColor lightGrayColor]];
            [lblMaximumWalkDistance setTextAlignment:UITextAlignmentLeft];
            [lblMaximumWalkDistance setText:MAXIMUM_WALK_DISTANCE_LABEL];
            [self addSubview:lblMaximumWalkDistance];
        }
        if(!sliderMaximumWalkDistance){
            sliderMaximumWalkDistance = [[UISlider alloc] initWithFrame:CGRectMake(230, 15, 70, 30)];
            [self addSubview:sliderMaximumWalkDistance];
        }

        if(!lblMaximumBikeDistance){
            lblMaximumBikeDistance = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblMaximumBikeDistance setBackgroundColor:[UIColor clearColor]];
            [lblMaximumBikeDistance setTextColor:[UIColor lightGrayColor]];
            [lblMaximumBikeDistance setTextAlignment:UITextAlignmentLeft];
            [lblMaximumBikeDistance setText:MAXIMUM_BIKE_DISTANCE];
            [self addSubview:lblMaximumBikeDistance];
        }
        if(!sliderMaximumBikeDistance){
            sliderMaximumBikeDistance = [[UISlider alloc] initWithFrame:CGRectMake(230, 15, 79, 30)];
            [self addSubview:sliderMaximumBikeDistance];
        }
        if(!lblPreferenceFastVsSafe){
            lblPreferenceFastVsSafe = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblPreferenceFastVsSafe setBackgroundColor:[UIColor clearColor]];
            [lblPreferenceFastVsSafe setTextColor:[UIColor lightGrayColor]];
            [lblPreferenceFastVsSafe setTextAlignment:UITextAlignmentLeft];
            [lblPreferenceFastVsSafe setText:PREFERENCE_FAST_VS_SAFE];
            [self addSubview:lblPreferenceFastVsSafe];
        }
        if(!switchPreferenceFastVsSafe){
            switchPreferenceFastVsSafe = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchPreferenceFastVsSafe setOn:NO];
            [self addSubview:switchPreferenceFastVsSafe];
        }
        
        if(!lblPreferenceFastVsFlat){
            lblPreferenceFastVsFlat = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 20)];
            [lblPreferenceFastVsFlat setBackgroundColor:[UIColor clearColor]];
            [lblPreferenceFastVsFlat setTextColor:[UIColor lightGrayColor]];
            [lblPreferenceFastVsFlat setTextAlignment:UITextAlignmentLeft];
            [lblPreferenceFastVsFlat setText:PREFERENCE_FAST_VS_FLAT];
            [self addSubview:lblPreferenceFastVsFlat];
        }
        if(!switchPreferenceFastVsFlat){
            switchPreferenceFastVsFlat = [[UISwitch alloc] initWithFrame:CGRectMake(220, 15, 30, 30)];
            [switchPreferenceFastVsFlat setOn:NO];
            [self addSubview:switchPreferenceFastVsFlat];
        }
        [lblSFMuniAdvisories setHidden:YES];
        [switchSFMuniAdvisories setHidden:YES];
        [lblBartAdvisories setHidden:YES];
        [switchBartAdvisories setHidden:YES];
        [lblACTransitAdvisories setHidden:YES];
        [switchACTransitAdvisories setHidden:YES];
        [lblCaltrainAdvisories setHidden:YES];
        [switchCaltrainAdvisories setHidden:YES];
        [lblPushNotification setHidden:YES];
        [switchPushNotification setHidden:YES];
        [lblPushNotificationFrequency setHidden:YES];
        [sliderPushNotificationFrequency setHidden:YES];
        [lblNotificationSound setHidden:YES];
        [lblUrgentNotifications setHidden:YES];
        [switchUrgentNotifications setHidden:YES];
        [lblStandardNotifications setHidden:YES];
        [switchStandardNotifications setHidden:YES];
        [lblNotificationTiming setHidden:YES];
        [lblWeekDayMorning setHidden:YES];
        [lblWeekDayMidDay setHidden:YES];
        [lblWeekDayEveningPeak setHidden:YES];
        [lblWeekDayNight setHidden:YES];
        [lblWeekends setHidden:YES];
        [lblTransitOnly setHidden:YES];
        [lblBikeOnly setHidden:YES];
        [lblBikeAndTransit setHidden:YES];
        [lblMaximumWalkDistance setHidden:YES];
        [sliderMaximumWalkDistance setHidden:YES];
        [lblMaximumBikeDistance setHidden:YES];
        [sliderMaximumBikeDistance setHidden:YES];
        [lblPreferenceFastVsSafe setHidden:YES];
        [switchPreferenceFastVsSafe setHidden:YES];
        [lblPreferenceFastVsFlat setHidden:YES];
        [switchPreferenceFastVsFlat setHidden:YES];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
