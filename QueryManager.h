//
//  QueryManager.h
//  RemoteActivity
//
//  Created by Drew McCormack on 3/3/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Host;

@interface QueryManager : NSObject {
    BOOL isQuerying;
    NSTimer *queryTimer;
    NSMutableSet *hostQueries;
}

+(id)sharedQueryManager;

-(void)startQuerying;
-(void)stopQuerying;

-(BOOL)isQuerying;

-(void)queryHost:(Host *)host;
-(void)queryHosts:(NSArray *)hosts;

@end
