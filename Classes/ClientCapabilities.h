//
//  ClientCapabilities.h
//  ShotgunApi
//
//  Created by Rob Blau on 6/11/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClientCapabilities : NSObject;

@property (retain, readwrite, nonatomic) NSString *platform;
@property (retain, readwrite, nonatomic) NSString *localPathField;

+ (id) clientCapabilities;
- (id) init;
- (void) dealloc;

@end
