//
//  Host.m
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "Host.h"
#import "BatchSystem.h"
#import "AccessShell.h"
#import "CoreDataUtilities.h"
#import "GlobalFunctions.h"


@implementation Host


+(void)initialize {
    [self setNotificationTriggeringKeys];
}


+(void)setNotificationTriggeringKeys {
    [self setKeys:[NSArray arrayWithObjects:@"jobs", nil]
        triggerChangeNotificationsForDependentKey:@"observedSelf"];
    [self setKeys:[NSArray arrayWithObjects:@"jobs", nil] triggerChangeNotificationsForDependentKey:@"queuedJobs"];
    [self setKeys:[NSArray arrayWithObjects:@"jobs", nil] triggerChangeNotificationsForDependentKey:@"finishedJobs"];
    [self setKeys:[NSArray arrayWithObjects:@"jobs", nil] triggerChangeNotificationsForDependentKey:@"runningJobs"];
}


-(id)copyWithZone:(NSZone *)zone {
    return [self retain];
}


// This 'hack' is needed to get bindings to work properly with the RealHostImageAndTextCell.
// Otherwise, binding to the RealHost object array does not update the host name in the 
// host table view correctly.
-(id)observedSelf {
    return self;
}


@end
