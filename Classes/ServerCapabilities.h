//
//  ServerCapabilities.h
//  ShotgunApi
//
//  Created by Rob Blau on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ServerCapabilities : NSObject {
    NSArray *version;
    BOOL isDev;
    BOOL hasPaging;
}

@property (readonly) BOOL isDev;
@property (readonly) BOOL hasPaging;

- (id)initWithHost: (NSString *)host andMeta:(NSDictionary *)meta;
- (void)_ensureJSONSupported;
- (BOOL)_isPaging;

@end
