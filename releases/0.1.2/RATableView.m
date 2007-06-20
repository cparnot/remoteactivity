//
//  RATableView.m
//  RemoteActivity
//
//  Created by Drew McCormack on 25/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RATableView.h"


@implementation RATableView

-(void)keyDown:(NSEvent *)event { 
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0]; 
    if (key == NSDeleteCharacter) {
        [self delete:self];
    } else {
        [super keyDown:event];
    } 
}

-(BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    if ( [anItem action] == @selector(delete:) ) {
        return [[self delegate] canRemove];
    }
    return [super validateUserInterfaceItem:anItem];
}

-(void)delete:(id)sender {
    if ( [[self delegate] canRemove] ) [[self delegate] remove:self];
}

@end