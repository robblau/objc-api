//
//  ShotgunEntity.h
//  UnitTests
//
//  Created by Rob Blau on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! @brief Represents a %Shotgun entity.
 *
 * @details
 * This is a thin wrapper around <a href="http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSMutableDictionary_Class/Reference/Reference.html#//apple_ref/doc/uid/20000141-17091">NSMutableDictionary</a>.
 */
@interface ShotgunEntity : NSMutableDictionary;

@property (retain, readonly, nonatomic) NSNumber *entityId;   ///< The id of the entity in %Shotgun
@property (retain, readonly, nonatomic) NSString *entityType; ///< The type of the entity in %Shotgun

+ (id)shotgunEntity; ///< Initialize an empty entity.
+ (id)shotgunEntityWithDictionary:(NSDictionary *)dictionary; ///< Initialize an entity with the provided dictionary.
+ (id)shotgunEntityWithJSON:(NSString *)json; ///< Initialize an entity with the dictionary value of the JSON string.
- (id)init;
- (id)initWithJSON:(NSString *)json;
- (void)dealloc;

@end
