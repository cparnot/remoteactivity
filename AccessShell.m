//
//  AccessShell.m
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "AccessShell.h"
#import "CoreDataUtilities.h"
#import "NSObjectExtensions.h"
#import "RealHost.h"
#import "HostQuery.h"
#import "GlobalFunctions.h"


// Placeholder strings
static NSString *HOSTNAME   = @"HOSTNAME";
static NSString *USERNAME   = @"USERNAME";


@interface AccessShell (Private)
-(NSMutableArray *)instantiateShellArguments:(NSArray *)arguments withDictionary:(NSDictionary *)instanceDict;
@end


@implementation AccessShell


-(void)awakeFromInsert {
    [super awakeFromInsert];
    [ManagedObjectContext() assignObject:self toPersistentStore:PrimaryStore()];
}


-(void)didTurnIntoFault {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [hostQueries release];
    [super didTurnIntoFault];
}


+(void)refreshAccessShells {
    NSString *defaultShellsFilePath = [[NSBundle mainBundle] pathForResource:@"DefaultAccessShells" ofType:@"plist"];
    NSArray *accessShellsPList = [NSArray arrayWithContentsOfFile:defaultShellsFilePath];
    NSManagedObjectContext *context = ManagedObjectContext();
    
    NSMutableSet *plistShellsSet = [NSMutableSet setWithCapacity:10];
    NSEnumerator *en = [accessShellsPList objectEnumerator];
    NSDictionary *dict = nil;
    while ( dict = [en nextObject] ) {
        AccessShell *shell = nil;
        NSArray *accessShells = [context fetchObjectsForEntityWithName:@"AccessShell" 
            andAttribute:@"name" equalToDescriptionForObject:[dict objectForKey:@"name"]];
        NSAssert( [accessShells count] <= 1, @"Too many AccessShells in ManagedObjectContext.");
        
        if ( [accessShells count] == 0 ) { // Create new AccessShell
            shell = [NSEntityDescription insertNewObjectForEntityForName:@"AccessShell" 
                inManagedObjectContext:context];        
            NSAssert( nil != shell, @"Failure to create shell in refreshAccessShells." );
        }
        else {
            shell = [accessShells lastObject];
        }
        
        // Update all values, including preexisting ones, in case they have changed in the plist.
        [shell setValuesForKeysWithDictionary:dict]; 
        
        [plistShellsSet addObject:shell];
    }
    
    // Remove any AccessShells no longer in the plist
    NSArray *allShellsSet = [context fetchObjectsForEntityWithName:@"AccessShell"];
    NSMutableSet *obsoleteSet = [NSMutableSet setWithArray:allShellsSet];
    [obsoleteSet minusSet:plistShellsSet];
    [context repeatedlyPerformSelector:@selector(deleteObject:) withObjects:[obsoleteSet allObjects]];
}


-(NSMutableArray *)instantiateShellArguments:(NSArray *)arguments withDictionary:(NSDictionary *)instanceDict {
    // Loop over arguments, and for each, substitute placeholders with concrete values
    NSMutableArray *instantiatedArguments = [NSMutableArray arrayWithCapacity:[arguments count]];
    NSEnumerator *argEnum = [arguments objectEnumerator];
    NSString *arg = nil;
    while ( arg = [argEnum nextObject] ) {
        NSMutableString *argCopy = [[arg mutableCopy] autorelease];
        NSEnumerator *placeholderKeyEnum = [instanceDict keyEnumerator];
        NSString *placeholderKey = nil;
        while ( placeholderKey = [placeholderKeyEnum nextObject] ) {
            NSString *placeholder = [NSString stringWithFormat:@"[[%@]]", placeholderKey];
            [argCopy replaceOccurrencesOfString:placeholder withString:[instanceDict objectForKey:placeholderKey] 
                options:NSLiteralSearch range:NSMakeRange(0, [argCopy length])];
        }
        [instantiatedArguments addObject:argCopy];
    }
    return instantiatedArguments;
}


// Factory method that creates a HostQuery, but does not initiate it. 
// Returns nil if there is not enough information to contact host.
-(HostQuery *)queryForHost:(RealHost *)aHost {
    NSString *shellPath = [self valueForKey:@"path"];
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:[self valueForKey:@"arguments"]];
    
    // Create instance dictionary for instantiation of argument templates
    NSString *usernameString = [aHost valueForKeyPath:@"username"];
    NSString *hostnameString = [aHost valueForKeyPath:@"address"];
    if ( nil == usernameString ) usernameString = @"";
    if ( nil == hostnameString ) return nil;
    NSDictionary *instanceDict = [NSDictionary dictionaryWithObjectsAndKeys:
        usernameString, USERNAME, hostnameString, HOSTNAME, nil];
    
    // Instantiate arguments for host
    NSMutableArray *instantiatedArguments = [self instantiateShellArguments:arguments withDictionary:instanceDict];
    
    // Get query script from BatchSystem
    NSString *queryScriptPath = [aHost valueForKeyPath:@"batchSystem.queryScriptPath"];
    if ( nil == queryScriptPath ) return nil;
    
    // Create and return HostQuery
    return [[[HostQuery alloc] initWithHost:aHost
        shellPath:shellPath 
        queryExecutablePath:queryScriptPath 
        shellArguments:instantiatedArguments] autorelease];
}


-(void)hostQueryDidFinish:(HostQuery *)hostQuery {
    [hostQueries removeObject:hostQuery];
}


@end
