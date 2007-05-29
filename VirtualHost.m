//
//  VirtualHost.m
//  Mental Case
//
//  Created by Drew McCormack on 26/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "VirtualHost.h"
#import "GlobalFunctions.h"


@interface VirtualHost (Private)

-(NSSet *)filteredJobsWithAppendedPredicate:(NSPredicate *)filterPred;

@end



@implementation VirtualHost


-(void)awakeFromInsert {
    [super awakeFromInsert];
    [ManagedObjectContext() assignObject:self toPersistentStore:InMemoryStore()];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemsDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:ManagedObjectContext()];  
    
    // Initialize fetch request and predicate
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:ManagedObjectContext()]];
    [self setValue:fetchRequest forKey:@"fetchRequest"];
    [self setValue:[NSPredicate predicateWithValue:YES] forKey:@"predicate"];
}


-(void)didTurnIntoFault {
    [jobs release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super didTurnIntoFault];
}


-(void)setUpdateNotificatons:(NSArray *)newNotifs {
    [self willAccessValueForKey:@"updateNotifications"];
    NSArray *notifs = [self primitiveValueForKey:@"updateNotifications"];
    [self didAccessValueForKey:@"updateNotifications"];
    
    // Stop observing old notifications
    if ( notifs ) {
        NSEnumerator *en = [notifs objectEnumerator];
        id notif;
        while ( notif = [en nextObject] ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:notif object:nil];
        }
    }
    
    // Observe new ones
    NSEnumerator *en = [newNotifs objectEnumerator];
    id notif;
    while ( notif = [en nextObject] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:notif object:self];
    }
    
    [self willChangeValueForKey:@"updateNotifications"];
    [self setPrimitiveValue:newNotifs forKey:@"updateNotifications"];
    [self didChangeValueForKey:@"updateNotifications"];
}


-(void)refresh:(id)notif {
    [self willChangeValueForKey:@"jobs"];
    [jobs release];
    jobs = nil; // Set to nil. Evaluated lazily.
    [self didChangeValueForKey:@"jobs"];
}


- (void)itemsDidChange:(NSNotification *)notification {
    NSEnumerator *enumerator;
    id object;
    BOOL refresh = NO;
    NSEntityDescription *entity = [[self valueForKey:@"fetchRequest"] entity];
    
    NSSet *updated = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *inserted = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *deleted = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    
    enumerator = [updated objectEnumerator];	
    while ((refresh == NO) && (object = [enumerator nextObject])) {
        if ([object entity] == entity) {
            refresh = YES;	
        }
    }
    
    enumerator = [inserted objectEnumerator];	
    while ((refresh == NO) && (object = [enumerator nextObject])) {
        if ([object entity] == entity) {
            refresh = YES;	
        }
    }
    
    enumerator = [deleted objectEnumerator];	
    while ((refresh == NO) && (object = [enumerator nextObject])) {
        if ([object entity] == entity) {
            refresh = YES;	
        }
    }
    
    if ( (refresh == NO) && (([updated count] == 0) && ([inserted count] == 0) && ([deleted count] == 0))) {
        refresh = YES;
    }
    
    if (refresh) [self refresh:nil];
    
}


-(NSSet *)jobs {
    if ( jobs == nil )  {
        NSError *error = nil;
        NSArray *results = nil;
        NSFetchRequest *fetchRequest = [self valueForKey:@"fetchRequest"];
        [fetchRequest setPredicate:
            [[self valueForKey:@"predicate"] predicateWithSubstitutionVariables:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSDate date],  @"DATE",
                    nil]]];
        results = [ManagedObjectContext() executeFetchRequest:fetchRequest error:&error];
        jobs = [[NSSet alloc] initWithArray:results];
    }
    return jobs;
}


-(NSSet *)filteredJobsWithAppendedPredicate:(NSPredicate *)filterPred {
    NSPredicate *pred = [self valueForKey:@"predicate"];
    if ( nil == pred ) return [NSSet set];
    NSPredicate *compoundPred = [NSCompoundPredicate andPredicateWithSubpredicates:
        [NSArray arrayWithObjects:pred, filterPred, nil]];
    NSFetchRequest *request = [self valueForKey:@"fetchRequest"];
    [request setPredicate:compoundPred];
    NSError *error = nil;
    NSArray *results = [ManagedObjectContext() executeFetchRequest:request error:&error];
    return [NSSet setWithArray:results];
}


-(NSSet *)queuedJobs {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == 100"];
    return [self filteredJobsWithAppendedPredicate:pred];
}


-(NSSet *)runningJobs {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == 200"];
    return [self filteredJobsWithAppendedPredicate:pred];
}


-(NSSet *)finishedJobs {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == 300"];
    return [self filteredJobsWithAppendedPredicate:pred];
}


@end
