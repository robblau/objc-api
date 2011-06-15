//
//  ServerCapabilities.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ServerCapabilities.h"

@implementation ServerCapabilities

@synthesize isDev;
@synthesize hasPaging;

-(id) initWithHost:(NSString *)host andMeta:(NSDictionary *)meta {
    self = [super init];
    if (self) {
        version = [meta objectForKey:@"version"];
        if (version) {
            isDev = NO;
            if ([version count] > 3)
                isDev = [[version objectAtIndex:3] isEqualToString:@"Dev"];
        } else {
            isDev = NO;
            version = [[[NSArray alloc] initWithObjects:
                        [NSNumber numberWithInt:0],
                        [NSNumber numberWithInt:0],
                        [NSNumber numberWithInt:0],
                        nil] autorelease];
        }
        [self _ensureJSONSupported];
        hasPaging = [self _isPaging];
    }
    return self;
}

-(void) _ensureJSONSupported {
    if ([(NSNumber *)[version objectAtIndex:0] unsignedIntegerValue] >= 2)
        if ([(NSNumber *)[version objectAtIndex:1] unsignedIntegerValue] >= 4)
            return;
    [NSException raise:@"Shotgun Error" 
                format:@"JSON API requires server version 2.4 or higher, server is %@", version];
}

-(BOOL) _isPaging {
    if ([(NSNumber *)[version objectAtIndex:0] unsignedIntegerValue] >= 2)
        if ([(NSNumber *)[version objectAtIndex:1] unsignedIntegerValue] >= 3)
            if ([(NSNumber *)[version objectAtIndex:2] unsignedIntegerValue] >= 4)
                return YES;
    return NO;
}

@end
