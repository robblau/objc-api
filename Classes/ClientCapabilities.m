//
//  ClientCapabilities.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/11/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "ClientCapabilities.h"

@implementation ClientCapabilities

@synthesize platform = platform_;
@synthesize localPathField = localPathField_;

+ (id)clientCapabilities
{
    return [[[ClientCapabilities alloc] init] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        self.platform = @"mac";
        self.localPathField = @"local_path_mac";
    }
    return self;
}

- (void)dealloc
{
    self.platform = Nil;
    self.localPathField = Nil;
    [super dealloc];
}

@end
