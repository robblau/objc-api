//
//  ServerCapabilities.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/11/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "ServerCapabilities.h"

@interface ServerCapabilities ()

@property (assign, readwrite, nonatomic) BOOL isDev;
@property (assign, readwrite, nonatomic) BOOL hasPaging;
@property (retain, readwrite, nonatomic) NSArray *version;

- (void)ensureJSONSupported_;
- (BOOL)isPaging_;

@end

@implementation ServerCapabilities

@synthesize isDev = isDev_;
@synthesize hasPaging = hasPaging_;
@synthesize version = version_;

+ (id)serverCapabilitiesWithHost:(NSString *)host andMeta:(NSDictionary *)meta
{
    return [[[ServerCapabilities alloc] initWithHost:host andMeta:meta] autorelease];
}

-(id) initWithHost:(NSString *)host andMeta:(NSDictionary *)meta {
    self = [super init];
    if (self) {
        self.version = [meta objectForKey:@"version"];
        if (self.version) {
            self.isDev = NO;
            if ([self.version count] > 3)
                self.isDev = [[self.version objectAtIndex:3] isEqualToString:@"Dev"];
        } else {
            self.isDev = NO;
            self.version = [[[NSArray alloc] initWithObjects:
                        [NSNumber numberWithInt:0],
                        [NSNumber numberWithInt:0],
                        [NSNumber numberWithInt:0],
                        nil] autorelease];
        }
        [self ensureJSONSupported_];
        self.hasPaging = [self isPaging_];
    }
    return self;
}

-(void) ensureJSONSupported_ {
    if ([(NSNumber *)[self.version objectAtIndex:0] unsignedIntegerValue] >= 2)
        if ([(NSNumber *)[self.version objectAtIndex:1] unsignedIntegerValue] >= 4)
            return;
    [NSException raise:@"Shotgun Error" 
                format:@"JSON API requires server version 2.4 or higher, server is %@", self.version];
}

-(BOOL) isPaging_ {
    if ([(NSNumber *)[self.version objectAtIndex:0] unsignedIntegerValue] >= 2)
        if ([(NSNumber *)[self.version objectAtIndex:1] unsignedIntegerValue] >= 3)
            if ([(NSNumber *)[self.version objectAtIndex:2] unsignedIntegerValue] >= 4)
                return YES;
    return NO;
}

- (void)dealloc
{
    self.version = Nil;
    [super dealloc];
}

@end
