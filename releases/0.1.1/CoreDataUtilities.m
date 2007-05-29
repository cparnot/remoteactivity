//
//  CoreDataUtilities.m
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "CoreDataUtilities.h"
#import "GlobalFunctions.h"


@implementation NSManagedObjectContext (RemoteActivityExtensions)


-(NSArray *)fetchObjectsForEntityWithName:(NSString *)entityName 
    andAttribute:(NSString *)attribute
    equalToDescriptionForObject:(id)object {
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    NSString *predicateString = [NSString stringWithFormat:@"%@ == %%@", attribute];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString, object];
    NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];
    [fetch setEntity:entity];
    [fetch setPredicate:predicate];
    return [self executeFetchRequest:fetch error:nil];
}


-(NSArray *)fetchObjectsForEntityWithName:(NSString *)entityName {
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];
    [fetch setEntity:entity];
    return [self executeFetchRequest:fetch error:nil];
}


+(NSArray *)fetchObjectsWithTemplate:(NSString *)templateName 
    substitutionDictionary:(NSDictionary *)substitutionDict
    error:(NSError **)error {
    NSManagedObjectContext *context = ManagedObjectContext();
    NSManagedObjectModel *model = ManagedObjectModel();
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:templateName 
        substitutionVariables:substitutionDict];
    return [context executeFetchRequest:fetchRequest error:error];
}


@end



@implementation NSManagedObject (RemoteActivityExtensions)

-(id)nonStandardDataAttributeForKey:(NSString *)key {
    [self willAccessValueForKey:key];
    id obj = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    if (obj == nil) {
        NSString *dataKey = [key stringByAppendingString:@"Data"];
        NSData *data = [self valueForKey:dataKey];
        if (data != nil) {
            obj = [NSUnarchiver unarchiveObjectWithData:data];
            [self setPrimitiveValue:obj forKey:key];
        }
    }
    return obj;
} 


-(void)setNonStandardDataAttribute:(id)object forKey:(NSString *)key {
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:object forKey:key];
    [self didChangeValueForKey:key];
    NSString *dataKey = [key stringByAppendingString:@"Data"];
    [self setValue:[NSArchiver archivedDataWithRootObject:object]
        forKey:dataKey];
} 

    
@end