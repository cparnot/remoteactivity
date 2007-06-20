//
//  GlobalFunctions.h
//  RemoteActivity
//
//  Created by Drew McCormack on 3/7/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSManagedObjectModel* ManagedObjectModel();
NSManagedObjectContext* ManagedObjectContext();
id PrimaryStore();
id InMemoryStore();
