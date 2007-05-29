//  RemoteActivityAppDelegate.m
//  RemoteActivity
//
//  Created by Drew McCormack on 14/01/06.
//  Copyright Drew McCormack 2006 . All rights reserved.

#import "RemoteActivityAppDelegate.h"
#import "BatchSystem.h"
#import "JobStatusValueTransformer.h"


@implementation RemoteActivityAppDelegate


+(void)initialize {
    // Register defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:300],   @"SecondsBetweenRefreshes",
            [NSNumber numberWithInt:168],   @"HoursBeforeRemovalOfFinishedJobs",
            [NSNumber numberWithBool:1],    @"JobsAreRemovedAutomatically",
            nil]];
    
    // Create value transformers
    [NSValueTransformer setValueTransformer:[[JobStatusValueTransformer new] autorelease] forName:@"JobStatusValueTransformer"];
}


-(NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel) return managedObjectModel;
	
    NSMutableSet *allBundles = [[NSMutableSet alloc] init];
    [allBundles addObject: [NSBundle mainBundle]];
    [allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}


-(NSString *)userApplicationSupportFolder {
    NSArray *appSupportFolders = 
        NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *userApplicationSupportFolder = [appSupportFolders lastObject];
    userApplicationSupportFolder = [userApplicationSupportFolder stringByAppendingPathComponent:@"Remote Activity"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if ( [fm fileExistsAtPath:userApplicationSupportFolder isDirectory:&isDir] ) {
        if ( !isDir ) {
            NSRunAlertPanel(@"File exists at Application Support path.", 
                @"The folder used by Remote Activity at ~/Library/Application Support/Remote Activity is currently occupied by a file. Move this file and restart Remote Activity.", 
                @"Quit", nil, nil);
            [[NSApplication sharedApplication] terminate:self];
        }
    }
    else {  
        [fm createDirectoryAtPath:userApplicationSupportFolder attributes:nil];
    }

    return userApplicationSupportFolder;
}


-(NSManagedObjectContext *)managedObjectContext {
    NSError *error;
    NSString *userApplicationSupportFolder = nil;
    NSURL *url;
    NSFileManager *fileManager;
    NSPersistentStoreCoordinator *coordinator;
    
    if (managedObjectContext) {
        return managedObjectContext;
    }
    
    fileManager = [NSFileManager defaultManager];
    userApplicationSupportFolder = [self userApplicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:userApplicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:userApplicationSupportFolder attributes:nil];
    }
    
    // Primary persistent store
    url = [NSURL fileURLWithPath: [userApplicationSupportFolder stringByAppendingPathComponent: @"RemoteActivity.xml"]];
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    primaryStore = [coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error];
    
    // In memory store
    inMemoryStore = [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
                                                
    // Create managed object context
    if ( primaryStore ){
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
        [[NSApplication sharedApplication] presentError:error];
    }    
    [coordinator release];
    
    return managedObjectContext;
}


-(id)primaryStore {
    return primaryStore;
}


-(id)inMemoryStore {
    return inMemoryStore;
}


-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


- (IBAction) saveAction:(id)sender {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


-(void)applicationDidFinishLaunching:(NSNotification *)notif {
    [[[self managedObjectContext] undoManager] removeAllActions];
}


-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    NSError *error;
    NSManagedObjectContext *context;
    int reply = NSTerminateNow;
    
    context = [self managedObjectContext];
    if (context != nil) {
        if ([context commitEditing]) {
            if (![context save:&error]) {
				
                // This default error handling implementation should be changed to make sure the error presented includes application specific error recovery. For now, simply display 2 panels.
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				NSLog(@"Error in saving: %@", error);
                if (errorResult == YES) { // Then the error was handled
                        reply = NSTerminateCancel;
                } else {
                        
                    // Error handling wasn't implemented. Fall back to displaying a "quit anyway" panel.
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                            reply = NSTerminateCancel;	
                    }
                }
            }
        } else {
            reply = NSTerminateCancel;
        }
    }
    return reply;
}


-(void)applicationDidResignActive:(NSNotification *)aNotification {
    NSError *error;
    [[self managedObjectContext] save:&error];
}


@end
