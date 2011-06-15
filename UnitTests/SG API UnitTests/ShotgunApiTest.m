//
//  ShotgunApiTests.m
//  ShotgunApiTests
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Shotgun.h"
#import <GHUnitIOS/GHUnit.h>

@interface ShotgunApiTest : GHTestCase {
    Shotgun *shotgun;
}
@end

@implementation ShotgunApiTest

- (void)setUpClass {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *config = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    shotgun = [[[Shotgun alloc] initWithUrl:[config objectForKey:@"url"]
                                 scriptName:[config objectForKey:@"script"] 
                                     andKey:[config objectForKey:@"key"]] autorelease];    
}

- (void)testConnection
{
    GHAssertNotNil(shotgun, @"initWithUrl returned nil");
}

- (void)testSchemaEntityRead 
{
    NSDictionary *entities = [shotgun schemaEntityRead];
    GHAssertNotNil([entities objectForKey:@"Shot"], @"Shot entity not found in schemaEntityRead");
}

- (void)testInfo
{
    NSDictionary *info = [shotgun info];
    GHAssertNotNil([info objectForKey:@"version"], @"version key not found in info dict");
}

- (void)testCreateUpdateDelete 
{
    // Create
    NSString *data = @"{ \
        \"code\": \"ObjC Unit Test Template\", \
        \"description\": \"This template should be retired by the unit tests if everything goes well.\", \
        \"entity_type\": \"Shot\" \
    }";
    ShotgunEntity *template = [shotgun createEntityOfType:@"TaskTemplate" withData:data];
    GHAssertTrue([template entityId] != 0, @"return id of Task Template was Nil");
    // Update
    NSString *updateData = @"{ \
        \"description\": \"Updated description.  Delete Next.\" \
    }";
    ShotgunEntity *updatedTemplate = [shotgun updateEntityOfType:@"TaskTemplate" withId:[template entityId] withData:updateData];
    GHAssertEqualStrings([updatedTemplate valueForKey:@"description"], @"Updated description.  Delete Next.", @"Description not updated");
    // Delete
    BOOL result = [shotgun deleteEntityOfType:@"TaskTemplate" withId:[template entityId]];
    GHAssertTrue(result, @"delete for Task Template returned False");
}

- (void)testFind 
{
    NSArray *results = [shotgun findEntitiesOfType:@"Shot"
                                       withFilters:@"[[\"sg_status_list\", \"is\", \"ip\"]]"
                        andFields:@"[\"sg_status_list\", \"code\", \"image\", \"sg_status_list\"]"];
    GHTestLog(@"Find returned: %@", results);
}

- (void)testUpload {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];
    [shotgun uploadThumbnailForEntityOfType:@"Asset" withId:[NSNumber numberWithInt:826] fromPath:path];
}

- (void)testDownload {
    NSData *data = [shotgun downloadAttachmentWithId:[NSNumber numberWithInt:6]];
    GHAssertTrue([data length] != 0, @"download for attachment returned no data.");
}

@end
