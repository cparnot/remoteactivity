//
//  BatchSystem.m
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "BatchSystem.h"
#import "CoreDataUtilities.h"
#import "NSObjectExtensions.h"
#import "GlobalFunctions.h"


@interface BatchSystem (Private)
+(NSSet *)batchSystemsForQueryScripts;
@end


@implementation BatchSystem


-(void)awakeFromInsert {
    [super awakeFromInsert];
    [ManagedObjectContext() assignObject:self toPersistentStore:PrimaryStore()];
}


+(NSArray *)batchSystemDirectories {    
    // Traverse application support directories, locating query script directories
    NSArray *appSupportDirectories = 
        NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
    NSMutableArray *batchSystemDirectories = [NSMutableArray arrayWithCapacity:10];
    NSEnumerator *pathEnum = [appSupportDirectories objectEnumerator];
    NSString *appSupportPath = nil;
    while ( appSupportPath = [pathEnum nextObject] ) {
        NSString *batchSystemDirPath = [appSupportPath stringByAppendingPathComponent:@"Remote Activity/Batch Systems"];
        [batchSystemDirectories addObject:batchSystemDirPath];
    }
    
    // Add the application bundle batch systems directory
    NSString *bundleBatchSystemsDirPath = 
        [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Batch Systems"];
    [batchSystemDirectories addObject:bundleBatchSystemsDirPath];
    
    return batchSystemDirectories;
}


+(NSSet *)batchSystemsForQueryScripts {
    NSArray *batchSystemDirectories = [self batchSystemDirectories];    
        
    // Locate query scripts in directories, and create a BatchSystem for each
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableSet *batchSystems = [NSMutableSet setWithCapacity:10];
    NSEnumerator *pathEnum = [batchSystemDirectories objectEnumerator];
    NSString *batchSystemDirPath = nil;
    while ( batchSystemDirPath = [pathEnum nextObject] ) {
        BOOL isDir;
        if ( [fm fileExistsAtPath:batchSystemDirPath isDirectory:&isDir] && isDir ) {
            NSArray *queryScripts = [fm directoryContentsAtPath:batchSystemDirPath];
            NSAssert( queryScripts != nil, @"Could not retrieve list of query scripts in refreshBatchSystems" );
            NSEnumerator *scriptEnum = [queryScripts objectEnumerator];
            NSString *scriptPath = nil;
            while ( scriptPath = [scriptEnum nextObject] ) {
                NSString *absoluteScriptPath = [batchSystemDirPath stringByAppendingPathComponent:scriptPath];
                BatchSystem *bs = [self batchSystemWithQueryScriptPath:absoluteScriptPath]; 
                    // Inserts new batch system if necessary
                [batchSystems addObject:bs];
            }
        }
    }

    return batchSystems;
} 


+(void)refreshBatchSystems {
    NSSet *batchSystemsWithScriptFiles = [self batchSystemsForQueryScripts];
    
    // Determine which BatchSystem objects exist that no longer have a script, and remove them.
    NSArray *allBatchSystems = [ManagedObjectContext() fetchObjectsForEntityWithName:@"BatchSystem"];
    NSMutableSet *obsoleteSet = [NSMutableSet setWithArray:allBatchSystems];
    [obsoleteSet minusSet:batchSystemsWithScriptFiles];
    [ManagedObjectContext() repeatedlyPerformSelector:@selector(deleteObject:) 
        withObjects:[obsoleteSet allObjects]];
}


// Retrieves BatchSystem from managed object context, or creates a new one and adds it if necessary.
+(BatchSystem *)batchSystemWithQueryScriptPath:(NSString *)path {
    NSArray *batchSystems = [ManagedObjectContext() fetchObjectsForEntityWithName:@"BatchSystem" 
        andAttribute:@"queryScriptPath" equalToDescriptionForObject:path];
    NSAssert( [batchSystems count] < 2, @"More than one BatchSystem corresponded to the same query script path." );
        
    // Create new batch system
    BatchSystem *batchSystem = nil;
    if ( [batchSystems count] == 0 ) { 
        batchSystem = [NSEntityDescription insertNewObjectForEntityForName:@"BatchSystem" 
            inManagedObjectContext:ManagedObjectContext()];
        [batchSystem setValue:path forKey:@"queryScriptPath"];
        [batchSystem setValue:[path lastPathComponent] forKey:@"name"];
    }
    else {
        batchSystem = [batchSystems lastObject];
    }
    
    return batchSystem;
}


@end
