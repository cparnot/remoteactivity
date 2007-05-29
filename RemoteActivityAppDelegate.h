//  RemoteActivityAppDelegate.h
//  RemoteActivity
//
//  Created by Drew McCormack on 14/01/06.
//  Copyright Drew McCormack 2006 . All rights reserved.

#import <Cocoa/Cocoa.h>

@interface RemoteActivityAppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
    
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    
    id primaryStore;
    id inMemoryStore;
}

-(NSManagedObjectModel *)managedObjectModel;
-(NSManagedObjectContext *)managedObjectContext;

-(id)primaryStore;
-(id)inMemoryStore;

-(IBAction)saveAction:sender;

@end
