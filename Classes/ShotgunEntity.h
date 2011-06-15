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
@interface ShotgunEntity : NSMutableDictionary {
    NSMutableDictionary *_internal;
}

@property (readonly) NSNumber *entityId;   ///< The id of the entity in %Shotgun
@property (readonly) NSString *entityType; ///< The type of the entity in %Shotgun

@end
