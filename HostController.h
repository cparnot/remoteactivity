//
//  HostController.h
//  RemoteActivity
//
//  Created by Drew McCormack on 3/17/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HostController : NSArrayController {
    IBOutlet NSWindow       *mainWindow;
    IBOutlet NSWindow       *hostSheetWindow;
    IBOutlet NSTextField    *hostNameTextField;
    IBOutlet NSTableView    *hostsTableView;
}


-(IBAction)closeHostSheet:(id)sender;
-(IBAction)editHost:(id)sender;

@end
