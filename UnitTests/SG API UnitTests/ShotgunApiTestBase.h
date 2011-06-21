//
//  ShotgunApiTestBase.h
//  UnitTests
//
//  Created by Rob Blau on 6/20/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>

#import "Shotgun.h"

@interface ShotgunApiTestBase : GHAsyncTestCase {
    Shotgun *shotgun;
}

@end
