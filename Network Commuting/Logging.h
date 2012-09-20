//
//  Logging.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
#ifndef Nimbler_Caltrain_Logging_h
#define Nimbler_Caltrain_Logging_h
// See http://iphoneincubator.com/blog/debugging/the-evolution-of-a-replacement-for-nslog for 

#define CUSTOM_RK_LOG_LEVELS RKLogLevelWarning  // Level of RestKit custom logging

#define NIMLOG_PERF1(...) // NSLog(__VA_ARGS__)  // Performance logging
#define NIMLOG_EVENT1(...) NSLog(__VA_ARGS__) // Key events
#define NIMLOG_URLS(...) NSLog(__VA_ARGS__)   // URL resources
#define NIMLOG_ERR1(...) NSLog(__VA_ARGS__)   // Error / exception logging
#define NIMLOG_ADDRESSES(...) // NSLog(__VA_ARGS__)  // Log addresses
#endif
