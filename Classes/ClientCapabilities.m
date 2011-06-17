//
//  ClientCapabilities.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/11/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "ClientCapabilities.h"


@implementation ClientCapabilities

- (id) init {
    self = [super init];
    if (self) {
        platform = @"mac";
        localPathField = @"local_path_mac";
    }
    return self;
}

@end
