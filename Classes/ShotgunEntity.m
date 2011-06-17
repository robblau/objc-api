//
//  ShotgunEntity.m
//  UnitTests
//
//  Created by Rob Blau on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ShotgunEntity.h"

@implementation ShotgunEntity

@dynamic entityId;
@dynamic entityType;

- (NSNumber *)entityId {
    return [self objectForKey:@"id"];
}

- (NSString *)entityType {
    return [self objectForKey:@"type"];
}

#pragma mark - Primitive Methods for NSDictionary and NSMutableDictionary

- (NSUInteger)count { return [_internal count]; }
- (id)objectForKey:(id)aKey { return [_internal objectForKey:aKey]; }
- (NSEnumerator *)keyEnumerator { return [_internal keyEnumerator]; }
- (void)setObject:(id)anObject forKey:(id)aKey { [_internal setObject:anObject forKey:aKey]; }
- (void)removeObjectForKey:(id)aKey { [_internal removeObjectForKey:aKey]; }

- (id)init { return [self initWithCapacity:0]; }
- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self != Nil)
        _internal = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    return self;
}

@end
