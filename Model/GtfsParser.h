//
//  GtfsParser.h
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GtfsParser : NSObject{
    NSManagedObjectContext *managedObjectContext;
}
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
- (void) parseAgencyDataAndStroreToDataBase:(NSString *)strFileData;
@end
