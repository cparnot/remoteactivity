//
//  MainController.h
//  RemoteActivity
//
//  Created by Drew McCormack on 14/01/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RBSplitView/RBSplitSubview.h"


@class GradientView;
@class FilterSegmentedControl;
@class HostController;

@interface MainController : NSWindowController {
    IBOutlet NSSearchField          *searchField;
    IBOutlet RBSplitSubview         *jobSplitSubview;
    IBOutlet RBSplitSubview         *jobInfoSplitSubview;
    IBOutlet NSTextField            *jobCountTextField;
    IBOutlet HostController         *hostsController;
    IBOutlet GradientView           *filterBarGradientView;
    IBOutlet FilterSegmentedControl *filterSegmentedControl;
}

+(id)sharedMainController;

-(IBAction)editHost:(id)sender;

-(IBAction)takeHostsOnline:(id)sender;
-(IBAction)takeHostsOffline:(id)sender;

-(IBAction)queryAllHosts:(id)sender;
-(IBAction)querySelectedHosts:(id)sender;

-(IBAction)expandJobInfo:(id)sender;
-(IBAction)toggleCollapsedStateOfJobInfo:(id)sender;

-(IBAction)undo:sender;
-(IBAction)redo:sender;

-(IBAction)toggleCollapsedStateOfWindow:(id)sender;

@end

