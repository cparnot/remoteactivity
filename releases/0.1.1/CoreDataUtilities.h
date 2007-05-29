//
//  CoreDataUtilities.h
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSManagedObjectContext (RemoteActivityExtensions)
// Fetch all objects of a given entity
-(NSArray *)fetchObjectsForEntityWithName:(NSString *)entityName;

// Fetch objects with a given attribute value
-(NSArray *)fetchObjectsForEntityWithName:(NSString *)entityName 
    andAttribute:(NSString *)attribute
    equalToDescriptionForObject:(id)object;
    
// Convenience method for fetching with a template
+(NSArray *)fetchObjectsWithTemplate:(NSString *)templateName 
    substitutionDictionary:(NSDictionary *)substitutionDict
    error:(NSError **)error;
@end


@interface NSManagedObject (RemoteActivityExtensions)
    
// Non-standard attributes
-(id)nonStandardDataAttributeForKey:(NSString *)key;
-(void)setNonStandardDataAttribute:(id)object forKey:(NSString *)key;

@end