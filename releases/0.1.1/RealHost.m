//
//  RealHost.m
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "RealHost.h"
#import "BatchSystem.h"
#import "AccessShell.h"
#import "CoreDataUtilities.h"
#import "GlobalFunctions.h"


@implementation RealHost


+(void)initialize {
    [self setNotificationTriggeringKeys];
}

+(void)setNotificationTriggeringKeys {
    [super setNotificationTriggeringKeys];
    [self setKeys:[NSArray arrayWithObjects:@"username",@"address",nil]
        triggerChangeNotificationsForDependentKey:@"userAndAddress"];
    [self setKeys:[NSArray arrayWithObjects:@"isActive", @"name", @"machineType", nil]
        triggerChangeNotificationsForDependentKey:@"observedSelf"];
}

-(void)commonAwake {
    NSProgressIndicator *indicator = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0,0,16,16)] autorelease];
    [indicator setStyle:NSProgressIndicatorSpinningStyle];
    [indicator setDisplayedWhenStopped:NO];
    [indicator animate:self];
    [indicator bind:@"animate" toObject:self withKeyPath:@"isRefreshing" options:nil];
    [self setValue:indicator forKey:@"refreshProgressIndicator"];
}


-(void)awakeFromInsert {
    [super awakeFromInsert];
    [ManagedObjectContext() assignObject:self toPersistentStore:PrimaryStore()];
    [self commonAwake];
}


-(void)awakeFromFetch {
    [super awakeFromFetch];
    [self commonAwake];
}


-(void)didTurnIntoFault {
    [[self valueForKey:@"refreshProgressIndicator"] unbind:@"animate"];
    [super didTurnIntoFault];
}


-(NSString *)userAndAddress {
    NSString *username = [self valueForKey:@"username"];
    NSString *address = [self valueForKey:@"address"];
    return ( username && address ?
             [NSString stringWithFormat:@"%@@%@", [self valueForKey:@"username"], [self valueForKey:@"address"]] : @"");
}


@end
