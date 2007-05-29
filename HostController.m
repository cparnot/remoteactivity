//
//  HostController.m
//  RemoteActivity
//
//  Created by Drew McCormack on 3/17/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "HostController.h"
#import "HostFormatter.h"
#import "ViewCell.h"
#import "Host.h"
#import "QueryManager.h"
#import "VirtualHost.h"
#import "GlobalFunctions.h"
#import "RealHost.h"


@interface HostController (Private)
-(BOOL)onlyRealHostsAreSelected;
-(int)numberOfRealHosts;
-(int)numberOfSelectedRealHosts;
@end


@implementation HostController


-(void)awakeFromNib {
    [super awakeFromNib];
    
    // Set sort descriptors
    NSSortDescriptor *prioritySortDesc = [[[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES] autorelease];
    NSSortDescriptor *nameSortDesc = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
    [self setSortDescriptors:[NSArray arrayWithObjects:prioritySortDesc, nameSortDesc, nil]];
    
    // Create library collection
    VirtualHost *v = [NSEntityDescription insertNewObjectForEntityForName:@"VirtualHost" inManagedObjectContext:ManagedObjectContext()];
    [v setValue:@"All Jobs" forKey:@"name"];
    [v setValue:[NSPredicate predicateWithValue:YES] forKey:@"predicate"];
    [v setValue:[NSNumber numberWithInt:1] forKey:@"priority"];
}

-(IBAction)editHost:(id)sender {
    if ( [[[self selectedObjects] lastObject] isKindOfClass:[VirtualHost class]] ) return;
    [NSApp beginSheet:hostSheetWindow modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)takeHostsOnline:(id)sender {
    NSEnumerator *en = [[self selectedObjects] objectEnumerator];
    id host;
    while ( host = [en nextObject] ) {
        [host setValue:[NSNumber numberWithBool:YES] forKey:@"isActive"];
    }
}

-(void)takeHostsOffline:(id)sender {
    NSEnumerator *en = [[self selectedObjects] objectEnumerator];
    id host;
    while ( host = [en nextObject] ) {
        [host setValue:[NSNumber numberWithBool:NO] forKey:@"isActive"];
    }
}

-(BOOL)onlyRealHostsAreSelected {
    BOOL retVal = ([[self selectedObjects] count] > 0);
    NSEnumerator *en = [[self selectedObjects] objectEnumerator];
    id host;
    while ( host = [en nextObject] ) retVal &= [host isKindOfClass:[RealHost class]];
    return retVal;
}

-(int)numberOfRealHosts {
    int retVal = 0;
    NSEnumerator *en = [[self arrangedObjects] objectEnumerator];
    id host;
    while ( host = [en nextObject] ) retVal += ([host isKindOfClass:[RealHost class]] ? 1 : 0);
    return retVal;
}

-(int)numberOfSelectedRealHosts {
    int retVal = 0;
    NSEnumerator *en = [[self selectedObjects] objectEnumerator];
    id host;
    while ( host = [en nextObject] ) retVal += ([host isKindOfClass:[RealHost class]] ? 1 : 0);
    return retVal;
}

-(BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ( [anItem action] == @selector(editHost:) ) {
        return ( [[self selectedObjects] count] == 1 && [[[self selectedObjects] lastObject] isKindOfClass:[RealHost class]] );
    }
    if ( [anItem action] == @selector(takeHostsOnline:) || [anItem action] == @selector(takeHostsOffline:) ) {
        return [self onlyRealHostsAreSelected];
    }
    if ( [anItem action] == @selector(querySelectedHosts:) ) {
        if ( [self numberOfSelectedRealHosts] > 1 ) 
            [anItem setTitle:@"Refresh Hosts"];
        else 
            [anItem setTitle:@"Refresh Host"];
        return [self onlyRealHostsAreSelected];
    } 
    if ( [anItem action] == @selector(queryAllHosts:) ) {
        return ([self numberOfRealHosts] > 0);
    }
    return YES;
}

-(id)newObject {
    return [[NSEntityDescription insertNewObjectForEntityForName:@"RealHost" inManagedObjectContext:ManagedObjectContext()] retain];
}


-(void)add:(id)sender {
    id newObject = [[self newObject] autorelease];
    [self addObject:newObject];
    [self setSelectedObjects:[NSArray arrayWithObject:newObject]];
    [hostNameTextField selectText:self];
    [self editHost:self];
}


-(BOOL)canRemove {
    BOOL canRemove = [super canRemove];
    NSEnumerator *en = [[self selectedObjects] objectEnumerator];
    Host *host;
    while ( canRemove && ( host = [en nextObject] ) ) {
        if ( [host isKindOfClass:[VirtualHost class]] ) canRemove = NO;
    }
    return canRemove;
}


-(IBAction)closeHostSheet:(id)sender {
    [NSApp endSheet:hostSheetWindow];
}


-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
    [hostSheetWindow orderOut:self];
    
    // Refresh host if it is active
    RealHost *selectedHost = [[self selectedObjects] lastObject];
    if ( [[selectedHost valueForKey:@"isActive"] boolValue] ) {
        [[QueryManager sharedQueryManager] queryHost:selectedHost];
    }
}

- (NSArray *)arrangeObjects:(NSArray *)objects {
	while ([[hostsTableView subviews] count] > 0)
    {
		[[[hostsTableView subviews] lastObject] removeFromSuperviewWithoutNeedingDisplay];
    }
	
	return [super arrangeObjects:objects];
}

@end
