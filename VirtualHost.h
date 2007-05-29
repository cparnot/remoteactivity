//
//  VirtualHost.h
//  RemoteActivity
//
//  Created by Drew McCormack on 11/27/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Host.h"


@interface VirtualHost : Host {
    NSSet *jobs;
}

-(void)refresh:(id)notif;

-(NSSet *)jobs;
-(NSSet *)queuedJobs;
-(NSSet *)runningJobs;
-(NSSet *)finishedJobs;

@end
