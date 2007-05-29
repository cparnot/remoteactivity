//
//  HostCell.h
//  RemoteActivity
//
//  Created by Drew McCormack on 8/14/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HostCell : NSTextFieldCell {
    @private
    NSImage	*icon;
    NSView *progressIndicator;
    unsigned int numRunningJobs, numQueuedJobs, numFinishedJobs;
}

- (void)setIcon:(NSImage *)anIcon;
- (NSImage *)icon;

-(NSView *)progressIndicator;
-(void)setProgressIndicator:(NSView *)newProgressIndicator;

@end