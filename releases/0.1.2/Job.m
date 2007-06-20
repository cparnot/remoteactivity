//
//  Job.m
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "Job.h"
#import "RealHost.h"
#import "CoreDataUtilities.h"
#import "GlobalFunctions.h"


@implementation Job


+(Job *)fetchJobWithHost:(RealHost *)host name:(NSString *)name andIdentifier:(NSNumber *)identifier {
    NSError *error = nil;
    NSArray *jobs = [NSManagedObjectContext fetchObjectsWithTemplate:@"JobsWithNameIdentifierHost" substitutionDictionary:
        [NSDictionary dictionaryWithObjectsAndKeys:name, @"NAME", 
            identifier, @"IDENTIFIER", 
            host, @"HOST", 
            nil] error:&error];
    NSAssert( jobs != nil, @"Error in fetch request in hostQueryDidFinish:" );
    NSAssert( [jobs count] < 2, @"Too many jobs fetched in hostQueryDidFinish:" );
    
    Job *job = nil;
    if ( [jobs count] > 0 ) job = [jobs lastObject];
    
    return job;
}


+(Job *)jobWithHost:(RealHost *)host name:(NSString *)name andIdentifier:(NSNumber *)identifier {
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:ManagedObjectContext()];
    [job setValuesForKeysWithDictionary:
        [NSDictionary dictionaryWithObjectsAndKeys:
            identifier,     @"identifier",
            host,           @"host",
            name,           @"name",
            nil]];
    return job;
}


-(void)awakeFromInsert {
    [super awakeFromInsert];
    [ManagedObjectContext() assignObject:self toPersistentStore:PrimaryStore()];
    [self setValue:[NSCalendarDate calendarDate] forKey:@"firstObservedDate"];
    [self setValue:[NSCalendarDate calendarDate] forKey:@"lastStatusChange"];
}


-(void)setStatus:(int)status {
    int oldStatus = [[self primitiveValueForKey:@"status"] intValue];
    [self willChangeValueForKey:@"status"];
    [self setPrimitiveValue:[NSNumber numberWithInt:status] forKey:@"status"];
    [self didChangeValueForKey:@"status"];
    if ( status != oldStatus ) [self setValue:[NSCalendarDate calendarDate] forKey:@"lastStatusChange"];
}


@end
