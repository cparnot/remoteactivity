//
//  BatchSystem.h
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BatchSystem : NSManagedObject {

}

+(NSArray *)batchSystemDirectories;
+(void)refreshBatchSystems; // Sync with disk

+(BatchSystem *)batchSystemWithQueryScriptPath:(NSString *)path; // recommended for creation of objects

@end
