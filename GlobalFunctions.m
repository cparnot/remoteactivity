//
//  GlobalFunctions.m
//  RemoteActivity
//
//  Created by Drew McCormack on 3/7/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "GlobalFunctions.h"
#import "RemoteActivityAppDelegate.h"


NSManagedObjectModel* ManagedObjectModel() {
    return [[NSApp delegate] managedObjectModel];
}

NSManagedObjectContext* ManagedObjectContext() {
    return [[NSApp delegate] managedObjectContext];
}

id PrimaryStore() {
    return [[NSApp delegate] primaryStore];
}

id InMemoryStore() {
    return [[NSApp delegate] inMemoryStore];
}

