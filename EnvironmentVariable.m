//
//  EnvironmentVariable.m
//  RemoteActivity
//
//  Created by Drew McCormack on 9/1/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "EnvironmentVariable.h"
#import "GlobalFunctions.h"


@implementation EnvironmentVariable


-(void)awakeFromInsert {
    [super awakeFromInsert];
    [ManagedObjectContext() assignObject:self toPersistentStore:PrimaryStore()];
}


+(id)environmentVariableWithName:(NSString *)name andValue:(NSString *)value {
    NSManagedObjectContext *context = ManagedObjectContext();
    EnvironmentVariable *environmentVariable = [NSEntityDescription insertNewObjectForEntityForName:@"EnvironmentVariable" inManagedObjectContext:context];
    
    [environmentVariable setValue:name forKey:@"name"];
    [environmentVariable setValue:value forKey:@"value"];
        
    return environmentVariable;
}


@end
