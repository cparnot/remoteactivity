//
//  JobStatusNotifier.h
//  RemoteActivity
//
//  Created by Drew McCormack on 8/31/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RealHost;

@interface JobStatusNotifier : NSObject {
    NSSet *completingJobs;
    NSSet *initiatingJobs;
    RealHost *host;
}

-(id)initWithCompletingJobs:(NSSet *)completingJobs initiatingJobs:(NSSet *)initiatingJobs onHost:(RealHost *)host;

-(void)notifyUserOfChanges;

@end
