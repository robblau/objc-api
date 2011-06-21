//
//  ShotgunEntity.m
//  UnitTests
//
//  Created by Rob Blau on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SBJson.h"

#import "ShotgunEntity.h"

@interface ShotgunEntity()

@property (assign, readwrite, nonatomic) NSMutableDictionary *internal;

@end

@implementation ShotgunEntity

@synthesize internal = internal_;
@dynamic entityId;
@dynamic entityType;

+ (id)shotgunEntity
{
    return [[[ShotgunEntity alloc] init] autorelease]; 
}

+ (id)shotgunEntityWithDictionary:(NSDictionary *)dictionary
{
    return [[[ShotgunEntity alloc] initWithDictionary:dictionary] autorelease];
}

+ (id)shotgunEntityWithJSON:(NSString *)json
{
    return [ShotgunEntity shotgunEntityWithDictionary:[json JSONValue]];
}

- (id)initWithJSON:(NSString *)json
{
    NSDictionary *dict = [json JSONValue];
    return [super initWithDictionary:dict];
}

- (NSNumber *)entityId {
    NSNumber *ret = [self objectForKey:@"id"];
    return ret;
}

- (NSString *)entityType {
    NSString *ret = [self objectForKey:@"type"];
    return ret;
}

#pragma mark - Primitive Methods for NSDictionary and NSMutableDictionary

- (NSUInteger)count
{
    return [self.internal count];
}

- (id)objectForKey:(id)aKey 
{
    return [self.internal objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [self.internal keyEnumerator];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    [self.internal setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
    [self.internal removeObjectForKey:aKey];
}

- (id)init
{
    return [self initWithCapacity:0];
}

- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self != Nil)
        self.internal = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    return self;
}

- (void)dealloc
{
    self.internal = Nil;
    [super dealloc];
}
@end
