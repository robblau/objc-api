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
    ShotgunRequest *req = [shotgun schemaEntityRead];
    [req startSynchronous];
    NSDictionary *entities = [req response];
    GHAssertNotNil([entities objectForKey:@"Shot"], @"Shot entity not found in schemaEntityRead");
}

- (void)testInfo
{
    ShotgunRequest *req = [shotgun info];
    [req startSynchronous];
    NSDictionary *info = [req response];
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
    ShotgunRequest *request1 = [shotgun createEntityOfType:@"TaskTemplate" withData:data];
    [request1 startSynchronous];
    ShotgunEntity *template = [request1 response];
    GHAssertTrue([template entityId] != 0, @"return id of Task Template was Nil");
    // Update
    NSString *updateData = @"{ \
        \"description\": \"Updated description.  Delete Next.\" \
    }";
    ShotgunRequest *request2 = [shotgun updateEntityOfType:@"TaskTemplate" withId:[template entityId] withData:updateData];
    [request2 startSynchronous];
    ShotgunEntity *updatedTemplate = [request2 response];
    GHAssertEqualStrings([updatedTemplate valueForKey:@"description"], @"Updated description.  Delete Next.", @"Description not updated");
    // Delete
    ShotgunRequest *request3 = [shotgun deleteEntityOfType:@"TaskTemplate" withId:[template entityId]];
    [request3 startSynchronous];
    BOOL result = [[request3 response] boolValue];
    GHAssertTrue(result, @"delete for Task Template returned False");
}

- (void)testFind 
{
    ShotgunRequest *request = [shotgun findEntitiesOfType:@"Shot"
                                       withFilters:@"[[\"sg_status_list\", \"is\", \"ip\"]]"
                        andFields:@"[\"sg_status_list\", \"code\", \"created_at\", \"image\", \"sg_status_list\"]"];
    [request startSynchronous];
    NSArray *results = [request response];
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
