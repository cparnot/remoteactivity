//
//  AccessShell.h
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BatchSystem;
@class RealHost;
@class HostQuery;


@interface NSObject (AccessShellDelegateMethods)
@end 


@interface AccessShell : NSManagedObject {
    NSMutableSet *hostQueries;
}

+(void)refreshAccessShells;

-(HostQuery *)queryForHost:(RealHost *)aHost;

@end
