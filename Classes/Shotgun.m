//
//  Shotgun.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

/*!
 * @todo Implement Authentication
 * @todo Figure out a way to do image url lookup in the background
 * @todo Figure out how to handle date fields
 * @todo Finish support for local paths
 * @todo Finish file upload/download asynchronous option
 */

#import "SBJson.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

#import "ShotgunConfig.h"
#import "ServerCapabilities.h"
#import "ClientCapabilities.h"

#import "Shotgun.h"
#import "ShotgunRequestPrivate.h"

@interface Shotgun()

@property (readwrite, nonatomic, retain) ShotgunConfig *config;
@property (readwrite, nonatomic, retain) ServerCapabilities *serverCaps;
@property (readwrite, nonatomic, retain) ClientCapabilities *clientCaps;

- (ShotgunRequest *)requestWithMethod_:(NSString *)method andParams:(id)params;
- (ShotgunRequest *)requestWithMethod_:(NSString *)method params:(id)params includeScriptName:(BOOL)includeScriptName returnFirst:(BOOL)first;

- (id)decodeResponseHeaders_:(NSDictionary *)headers andBody:(NSString *)body;
- (void)responseErrors_:(id)response;

- (id)transformInboundData_:(id)data;
- (id)transformOutboundData_:(id)data;
- (id)visitData_:(id)data withVisitor:(id (^)(id))visitor;

- (NSDictionary *)buildPayloadWithConfig_:(ShotgunConfig *)config Method:(NSString *)method andParams:(NSDictionary *)params includeScriptName:(BOOL)includeScriptName;

- (NSString *)getSessionToken_;

- (NSArray *)parseRecords_:(id)records;
- (NSString *)buildThumbUrlForEntity_:(ShotgunEntity *)entity;

- (NSArray *)listFromObj_:(id)obj;
- (NSArray *)listFromObj_:(id)obj withKeyName:(NSString *)keyName andValueName:(NSString *)valueName;

@end

@implementation Shotgun

@synthesize config = config_;
@synthesize clientCaps = clientCaps_;
@synthesize serverCaps = serverCaps_;

#pragma mark - Initialize

+ (id)shotgunWithUrl:(NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key
{
    return [[[Shotgun alloc] initWithUrl:url scriptName:scriptName andKey:key] autorelease];
}

- (id)initWithUrl:(NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key
{
    self = [super init];
    if (self) {
        ShotgunConfig *aConfig = [ShotgunConfig config];
        aConfig.apiKey = key;
        aConfig.scriptName = scriptName;
        NSURL *parseUrl = [NSURL URLWithString:[url lowercaseString]];
        aConfig.scheme = [parseUrl scheme];
        if (!([aConfig.scheme isEqualToString:@"http"] || [aConfig.scheme isEqualToString:@"https"]))
            [NSException raise:@"Invalid url" format:@"url must use http or https got '%@'", url];
        aConfig.server = [parseUrl host];
        NSString *apiBase = [parseUrl path];
        if ([apiBase isEqualToString:@""])
            aConfig.apiPath = [NSString stringWithFormat:@"/%@/json", aConfig.apiVer];
        else
            aConfig.apiPath = [NSString stringWithFormat:@"%@/%@/json", apiBase, aConfig.apiVer];
        self.config = aConfig;
        
        // Get and check server capabilities
        ShotgunRequest *req = [self info];
        [req startSynchronous];
        NSDictionary *info = [req response];
        if (info)
            self.serverCaps = [ServerCapabilities serverCapabilitiesWithHost:self.config.server andMeta:info];
        else
            return Nil;
        // Get and check client capabilities
        self.clientCaps = [ClientCapabilities clientCapabilities];
    }
    return self;
}

#pragma mark Query Information

- (ShotgunRequest *)info 
{
    return [self requestWithMethod_:@"info" params:Nil includeScriptName:NO returnFirst:NO];
}

- (ShotgunRequest *)findEntityOfType:(NSString *)entityType withFilters:(id)filters
{
    return [self findEntityOfType:entityType withFilters:filters andFields:Nil];
}

- (ShotgunRequest *)findEntityOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
{
    return [self findEntityOfType:entityType withFilters:filters andFields:fields andOrder:Nil andFilterOperator:Nil retiredOnly:NO];
}

- (ShotgunRequest *)findEntityOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                          andOrder:(id)order andFilterOperator:(NSString *)filterOperator retiredOnly:(BOOL)retiredOnly
{
    ShotgunRequest *request = [self findEntitiesOfType:entityType
                                           withFilters:filters 
                                             andFields:fields 
                                              andOrder:order 
                                     andFilterOperator:filterOperator
                                              andLimit:1 
                                               andPage:0 
                                           retiredOnly:retiredOnly];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *headers, NSString *body) {
        NSArray *results = oldPost(headers, body);
        if ([results count] > 0)
            return [results objectAtIndex:0];
        return Nil;        
    }];
    return request;
}

- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters
{
    return [self findEntitiesOfType:entityType withFilters:filters andFields:Nil];
}

- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
{
    return [self findEntitiesOfType:entityType withFilters:filters andFields:fields 
                           andOrder:Nil andFilterOperator:Nil andLimit:0 andPage:0 retiredOnly:NO];
}

- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator
{
    return [self findEntitiesOfType:entityType withFilters:filters andFields:fields 
                           andOrder:order andFilterOperator:filterOperator andLimit:0 andPage:0 retiredOnly:NO];
}
            
- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator andLimit:(NSUInteger)limit
                        andPage:(NSUInteger)page retiredOnly:(BOOL)retiredOnly
{
    // Convert JSON args to objects
    id checkedFilters = filters;
    if ([checkedFilters isKindOfClass:[NSString class]])
        checkedFilters = [filters JSONValue];
    id checkedFields = fields;
    if ([checkedFields isKindOfClass:[NSString class]])
        checkedFields = [fields JSONValue];
    id checkedOrder = order;
    if ([checkedOrder isKindOfClass:[NSString class]])
        checkedOrder = [order JSONValue];

    // Convert simple array filter to a dictionary
    if ([checkedFilters isKindOfClass:[NSArray class]]) {
        NSMutableDictionary *newFilters = [NSMutableDictionary dictionary];
        if ((filterOperator == Nil) || [filterOperator isEqualToString:@"all"])
            [newFilters setObject:@"and" forKey:@"logical_operator"];
        else
            [newFilters setObject:@"or" forKey:@"logical_operator"];
        
        NSMutableArray *conditions = [NSMutableArray array];
        for (NSArray *filter in checkedFilters)
            [conditions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [filter objectAtIndex:0], @"path",
                                        [filter objectAtIndex:1], @"relation",
                                        [filter subarrayWithRange:NSMakeRange(2, [filter count]-2)], @"values",
                                    nil]];
        [newFilters setObject:conditions forKey:@"conditions"];
        checkedFilters = newFilters;
    } else if (filterOperator != Nil)
        [NSException raise:@"Shotgun Error" format:@"Use of filter_operator only valid when passing in an array filter."];
    
    // Defaults for fields
    if (checkedFields == Nil)
        checkedFields = [NSArray arrayWithObjects:@"id", nil];
    
    // Type check variable typed arguments
    if (![checkedFilters isKindOfClass:[NSDictionary class]])
        [NSException raise:@"Value Error" format:@"Invalid filters: %@", filters];
    if (![checkedFields isKindOfClass:[NSArray class]])
        [NSException raise:@"Value Error" format:@"Invalid fields: %@", fields];
    if ((checkedOrder != Nil) && ![checkedOrder isKindOfClass:[NSArray class]])
        [NSException raise:@"Value Error" format:@"Invalid order: %@", order];
        
    // Inital parameters
    __block NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        entityType, @"type",
                                        checkedFilters, @"filters",
                                        checkedFields, @"return_fields",
                                        retiredOnly ? @"retired" : @"active", @"return_only",
                                        [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithUnsignedInteger:self.config.recordsPerPage], @"entities_per_page",
                                                [NSNumber numberWithInt:1], @"current_page",
                                          nil], @"paging",
                                    nil];
    
    if (self.serverCaps.hasPaging)
        [params setObject:[NSNumber numberWithBool:YES] forKey:@"return_paging_info"];

    // Order
    if (checkedOrder != Nil) {
        NSMutableArray *sortList = [NSMutableArray array];
        for (NSDictionary *sort in checkedOrder) {
            NSString *fieldName = [sort objectForKey:@"column"];
            if (fieldName == Nil)
                fieldName = [sort objectForKey:@"field_name"];
            NSString *direction = [sort objectForKey:@"direction"];
            if (direction == Nil)
                direction = @"asc";
            [sortList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        fieldName, @"field_name",
                                        direction, @"direction",
                                  nil]];
        }
        [params setObject:sortList forKey:@"sorts"];
    }
    
    if (limit && limit <= self.config.recordsPerPage) {
        [[params objectForKey:@"paging"] 
            setObject:[NSNumber numberWithUnsignedInteger:limit] forKey:@"entities_per_page"];
        if (page == 0)
            page = 1;
    }
    
    // Paging return
    if (page != 0) {
        if (self.serverCaps.hasPaging)
            [params setObject:[NSNumber numberWithBool:NO] forKey:@"return_paging_info"];
        
        [[params objectForKey:@"paging"] 
                setObject:[NSNumber numberWithUnsignedInteger:page] forKey:@"current_page"];
        ShotgunRequest *request = [self requestWithMethod_:@"read" andParams:params];
        ShotgunPostProcessBlock oldPost = [request postProcessBlock];
        [request setPostProcessBlock:^id (NSDictionary *headers, NSString *body) {
            NSArray *records = [oldPost(headers, body) objectForKey:@"entities"];
            if (records == Nil)
                records = [NSArray array];
            NSArray *ret = [self parseRecords_:records];
            return ret;
        }];
        return request;
    }
    
    // Get as many pages as needed
    ShotgunRequest *request = [self requestWithMethod_:@"read" andParams:params];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *headers, NSString *body) {
        NSDictionary *result = oldPost(headers, body);
        NSArray *entities = [result objectForKey:@"entities"];
        NSMutableArray *records = [NSMutableArray array];
        NSArray *returnRecords = records;
        while (entities) {
            [records addObjectsFromArray:entities];
            if (limit && ([records count] >= limit)) {
                returnRecords = [records subarrayWithRange:NSMakeRange(0, limit)];
                break;
            }
            // result['paging_info']['entity_count'] == len(records)
            if ([[[result objectForKey:@"paging_info"] objectForKey:@"entity_count"] unsignedIntegerValue] == [records count])
                break;
            NSNumber *currentPage = [[params objectForKey:@"paging"] objectForKey:@"current_page"];
            NSNumber *nextPage = [NSNumber numberWithUnsignedInteger:[currentPage unsignedIntegerValue]+1];
            [[params objectForKey:@"paging"] setObject:nextPage forKey:@"current_page"];
            ShotgunRequest *nextPageRequest = [self requestWithMethod_:@"read" andParams:params];
            [nextPageRequest startSynchronous];
            result = [nextPageRequest response];
        }
        NSArray *ret = [self parseRecords_:returnRecords];
        return ret;
    }];
    return request;
}

#pragma mark Modify Information

- (ShotgunRequest *)createEntityOfType:(NSString *)entityType withData:(id)data
{
    return [self createEntityOfType:entityType withData:data returnFields:Nil];
}

- (ShotgunRequest *)createEntityOfType:(NSString *)entityType withData:(id)data returnFields:(id)returnFields
{
    NSArray *argFields = returnFields;
    if (argFields == Nil)
        argFields = [NSArray arrayWithObjects:@"id", nil];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                entityType, @"type",
                                [self listFromObj_:data], @"fields",
                                argFields, @"return_fields",
                             nil];
    ShotgunRequest *request = [self requestWithMethod_:@"create" params:params includeScriptName:YES returnFirst:YES];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *requests, NSString *body) {
        id records = oldPost(requests, body);
        NSArray *parsed = [self parseRecords_:records];
        NSDictionary *ret = [parsed objectAtIndex:0];
        return ret;
    }];
    return request;
}

- (ShotgunRequest *)updateEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId withData:(id)data
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                                [self listFromObj_:data], @"fields",
                             nil];
    ShotgunRequest *request = [self requestWithMethod_:@"update" andParams:params];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *requests, NSString *body) {
        id records = oldPost(requests, body);
        NSArray *parsed = [self parseRecords_:records];
        NSDictionary *ret = [parsed objectAtIndex:0];
        return ret;
    }];
    return request;
}

- (ShotgunRequest *)deleteEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                             nil];
    ShotgunRequest *ret = [self requestWithMethod_:@"delete" andParams:params];
    return ret;
}

- (ShotgunRequest *)reviveEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                             nil];
    ShotgunRequest *ret = [self requestWithMethod_:@"revive" andParams:params];
    return ret;
}

- (ShotgunRequest *)batch:(id)requests
{
    NSMutableArray *calls = [NSMutableArray array];
    for (NSDictionary *request in requests) {
        NSString *requestType = [request objectForKey:@"request_type"];
        if ([requestType isEqualToString:@"create"]) {
            NSSet *requiredKeys = [NSSet setWithObjects:@"entity_type", @"data", nil];
            if (![requiredKeys isSubsetOfSet:[NSSet setWithArray:[request allKeys]]])
                [NSException raise:@"Shotgun Error" format:@"Batch create request missing a required key: %@ (was %@)", requiredKeys, request];
            NSArray *returnFields = [request objectForKey:@"return_fields"];
            if (returnFields == Nil)
                returnFields = [NSArray arrayWithObjects:@"id", nil];
            [calls addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @"create", @"request_type",
                                    [request objectForKey:@"entity_type"], @"type",
                                    [self listFromObj_:[request objectForKey:@"data"]], @"fields",
                                    returnFields, @"return_fields",
                               nil]];
        } else if ([requestType isEqualToString:@"update"]) {
            NSSet *requiredKeys = [NSSet setWithObjects:@"entity_type", @"entity_id", @"data", nil];
            if (![requiredKeys isSubsetOfSet:[NSSet setWithArray:[request allKeys]]])
                [NSException raise:@"Shotgun Error" format:@"Batch update request missing a required key: %@ (was %@)", requiredKeys, request];
            [calls addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @"update", @"request_type",
                                    [request objectForKey:@"entity_type"], @"type",
                                    [request objectForKey:@"entity_id"], @"id",
                                    [self listFromObj_:[request objectForKey:@"data"]], @"fields",
                               nil]];
        } else if ([requestType isEqualToString:@"delete"]) {
            NSSet *requiredKeys = [NSSet setWithObjects:@"entity_type", @"entity_id", nil];
            if (![requiredKeys isSubsetOfSet:[NSSet setWithArray:[request allKeys]]])
                [NSException raise:@"Shotgun Error" format:@"Batch delete request missing a required key: %@ (was %@)", requiredKeys, request];
            [calls addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @"delete", @"request_type",
                                    [request objectForKey:@"entity_type"], @"type",
                                    [request objectForKey:@"entity_id"], @"id",
                               nil]];
        } else {
            [NSException raise:@"Shotgun Error" format:@"Invalid requestType '%@' for batch", requestType];
        }
    }
    ShotgunRequest *request = [self requestWithMethod_:@"batch" andParams:calls];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *requests, NSString *body) {
        id records = oldPost(requests, body);
        NSArray *parsed = [self parseRecords_:records];
        return parsed;
    }];
    return request;
}

#pragma mark Meta Schema

- (ShotgunRequest *)schemaEntityRead
{
    return [self requestWithMethod_:@"schema_entity_read" andParams:Nil];
}

- (ShotgunRequest *)schemaRead 
{
    return [self requestWithMethod_:@"schema_read" andParams:Nil];
}

- (ShotgunRequest *)schemaFieldReadForEntityOfType:(NSString *)entityType 
{
    return [self schemaFieldReadForEntityOfType:entityType forField:Nil];
}

- (ShotgunRequest *)schemaFieldReadForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName 
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:entityType, @"type", nil];
    if (fieldName != Nil)
        [params setObject:fieldName forKey:@"field_name"];
    return [self requestWithMethod_:@"schema_field_read" andParams:params];
}

- (ShotgunRequest *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType 
                               withDisplayName:(NSString *)displayName
{
    return [self schemaFieldCreateForEntityOfType:entityType ofDataType:dataType withDisplayName:displayName andProperties:Nil];
}

- (ShotgunRequest *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType
                               withDisplayName:(NSString *)displayName andProperties:(id)properties
{
    NSMutableArray *propertiesParam = [NSMutableArray arrayWithObjects:
                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"name", @"property_name",
                                                    displayName, @"value",
                                              nil],
                                        nil];
    [propertiesParam addObjectsFromArray:[self listFromObj_:properties
                                                 withKeyName:@"property_name"
                                                andValueName:@"value"]];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                entityType, @"type",
                                dataType, @"data_type",
                                propertiesParam, @"properties",
                             nil];
    return [self requestWithMethod_:@"schema_field_create" andParams:params];
}

- (ShotgunRequest *)schemaFieldUpdateForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName withProperties:(NSDictionary *)properties
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                entityType, @"type",
                                fieldName, @"field_name",
                                [self listFromObj_:properties withKeyName:@"property_name" andValueName:@"value"], @"properties",
                            nil];
    return [self requestWithMethod_:@"schema_field_update" andParams:params];
}

- (ShotgunRequest *)schemaFieldDeleteForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName 
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                entityType, @"type",
                                fieldName, @"field_name",
                             nil];
    return [self requestWithMethod_:@"schema_field_delete" andParams:params];
}

- (void)setSessionUuid:(NSString *)uuid
{
    self.config.sessionUuid = uuid;
}

#pragma mark Upload and Download Files

- (NSNumber *)uploadThumbnailForEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path 
{
    return [self uploadForEntityOfType:entityType withId:entityId fromPath:path forField:@"thumb_image" withDisplayName:Nil andTagList:Nil];
}

- (NSNumber *)uploadForEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path 
{
    return [self uploadForEntityOfType:entityType withId:entityId fromPath:path forField:Nil withDisplayName:Nil andTagList:Nil];    
}

- (NSNumber *)uploadForEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path forField:(NSString *)fieldName
                    withDisplayName:(NSString *)displayName andTagList:(NSString *)tagList
{
    path = [path stringByExpandingTildeInPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        [NSException raise:@"Value Error" format:@"Path must be a valid file, got '%@'", path];
    
    BOOL isThumbnail = [fieldName isEqualToString:@"thumb_image"];

    NSURL *url;
    ASIFormDataRequest *request;
    if (isThumbnail) {
        url = [[[NSURL alloc] initWithScheme:self.config.scheme host:self.config.server path:@"/upload/publish_thumbnail"] autorelease];
        request = [ASIFormDataRequest requestWithURL:url];
        [request setFile:path forKey:@"thumb_image"];
    } else {
        url = [[[NSURL alloc] initWithScheme:self.config.scheme host:self.config.server path:@"/upload/upload_file"] autorelease];
        request = [ASIFormDataRequest requestWithURL:url];
        if (displayName == Nil)
            displayName = [path lastPathComponent];
        if (fieldName != Nil)
            [request setPostValue:fieldName forKey:@"field_name"];
        [request setPostValue:displayName forKey:@"display_name"];
        [request setPostValue:tagList forKey:@"tag_list"];
        [request setFile:path forKey:@"file"];
    }
    
    [request setPostValue:entityType forKey:@"entity_type"];
    [request setPostValue:entityId forKey:@"entity_id"];
    [request setPostValue:self.config.scriptName forKey:@"script_name"];
    [request setPostValue:self.config.apiKey forKey:@"script_key"];
    if (self.config.sessionUuid != Nil)
        [request setPostValue:self.config.sessionUuid forKey:@"session_uuid"];

    [request setPostFormat:ASIMultipartFormDataPostFormat];
    [request startSynchronous];
    NSError *error = [request error];
    if (error) {
        if ([request responseStatusCode] == 500)
            [NSException raise:@"Shotgun Error" format:@"Server encountered an internal error. " \
                "\n%@\n(%@)\n%@", [request url], request , error];
        else
            [NSException raise:@"Shotgun Error" format:@"Unanticipated error occurred uploading " \
                "%@: %@", path, error];
    }
    NSString *response = [request responseString];
    NSLog(@"Response: %@", response);
    if ([response characterAtIndex:0] != '1')
        [NSException raise:@"File upload error" format:@"Could not upload file successfully, " \
            "but not sure why.\nPath: %@\nUrl: %@\nError: %@", path, url, response];

    NSNumber *resultId = [NSNumber numberWithInt:0];
    return resultId;
}

- (NSData *)downloadAttachmentWithId:(NSNumber *)attachmentId
{
    NSString *sessionId = [self getSessionToken_];
    
    NSString *path = [NSString stringWithFormat:@"/file_serve/%@", attachmentId];
    NSURL *url = [[[NSURL alloc] initWithScheme:self.config.scheme host:self.config.server path:path] autorelease];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setUserAgent:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; " \
        "rv:1.9.0.7) Gecko/2009021906 Firefox/3.0.7"];
    NSDictionary *properties = [NSMutableDictionary dictionary];
    [properties setValue:@"0" forKey:NSHTTPCookieVersion];
    [properties setValue:@"_session_id" forKey:NSHTTPCookieName];
    [properties setValue:sessionId forKey:NSHTTPCookieValue];
    [properties setValue:self.config.server forKey:NSHTTPCookieDomain];
    [properties setValue:@"/" forKey:NSHTTPCookiePath];
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:properties];
    [request setUseCookiePersistence:NO];
    [request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
    [request startSynchronous];
    NSError *error = [request error];
    if (error)
        [NSException raise:@"Shotgun Error" format:@"Failed to open %@, with code: %@ and message %@",
         url, [error code], [error description]];
    NSData *ret = [request responseData];
    return ret;
}

#pragma mark - Destruction

- (void)dealloc 
{
    self.clientCaps = Nil;
    self.serverCaps = Nil;
    self.config = Nil;
    [super dealloc];
}

#pragma mark - Private Category Methods

- (id)decodeResponseHeaders_:(NSDictionary *)headers andBody:(NSString *)body
{
    NSString *contentType = [headers objectForKey:@"content-type"];
    if (contentType == Nil)
        contentType = @"application/json";
    else
        contentType = [contentType lowercaseString];
    if ([contentType hasPrefix:@"application/json"] || [contentType hasPrefix:@"text/javascript"])
        return [body JSONValue];
    return body;
}

- (void)responseErrors_:(id)response
{
    if ([response isKindOfClass:[NSDictionary class]]) {
        id exception = [(NSDictionary *)response objectForKey:@"exception"];
        if (exception != Nil) {
            NSString *msg = [(NSDictionary *)response objectForKey:@"message"];
            if (msg == Nil)
                msg = @"Unknown Error";
            [NSException raise:@"Response Error" format:@"%@", msg];
        }
    }
}

- (NSString *)getSessionToken_ {
    if (self.config.sessionToken != Nil)
        return self.config.sessionToken;
    
    ShotgunRequest *request = [self requestWithMethod_:@"get_session_token" andParams:Nil];
    [request startSynchronous];
    NSDictionary *results = [request response];
    NSString *sessionToken = [results objectForKey:@"session_id"];
    if (sessionToken == Nil)
        [NSException raise:@"Shotgun Error" format:@"Could not extract session_id from %@", results];
    self.config.sessionToken = sessionToken;
    return self.config.sessionToken;
}

- (ShotgunRequest *)requestWithMethod_:(NSString *)method andParams:(id)params
{
    return [self requestWithMethod_:method params:params includeScriptName:YES returnFirst:NO];
}

- (ShotgunRequest *)requestWithMethod_:(NSString *)method params:(id)params includeScriptName:(BOOL)includeScriptName returnFirst:(BOOL)first
{
    NSDictionary *paramsTransformed = [self transformOutboundData_:params];
    NSDictionary *payload = [self buildPayloadWithConfig_:self.config Method:method andParams:paramsTransformed includeScriptName:includeScriptName];
    NSString *encodedPayload = [payload JSONRepresentation];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"content-type"];
    
    ShotgunRequest *request = 
        [ShotgunRequest shotgunRequestWithConfig:self.config 
                                            path:self.config.apiPath
                                            body:encodedPayload 
                                         headers:headers andHTTPMethod:@"POST"];
    [request setPostProcessBlock:^id (NSDictionary *headers, NSString *body) {
        // Parse the results
        id response = [self decodeResponseHeaders_:headers andBody:body];
        [self responseErrors_:response];
        id transformedResponse = [self transformInboundData_:response];
        if ([transformedResponse isKindOfClass:[NSDictionary class]]) {
            id results = [(NSDictionary *)transformedResponse objectForKey:@"results"];
            if (results == Nil)
                return transformedResponse;
            if (first && [results isKindOfClass:[NSArray class]])
                return [(NSArray *)results objectAtIndex:0];
            return results;
        }
        return transformedResponse;
    }];
    return request;
}

- (NSArray *)parseRecords_:(id)records 
{
    NSMutableArray *ret = [NSMutableArray array];
    if (records == Nil)
        return ret;
    NSArray *iteratee;
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue setMaxConcurrentOperationCount:4];
    queue.name = @"Thumbnail Converting Queue";
    NSLog(@"Converting thumbs on queue: %@", queue.name);
    if (![records isKindOfClass:[NSArray class]])
        iteratee = [NSArray arrayWithObject:records];
    else
        iteratee = records;
    for (id record in iteratee) {
        if (![record isKindOfClass:[NSDictionary class]]) {
            [ret addObject:record];
            continue;
        }
        ShotgunEntity *entity = [ShotgunEntity shotgunEntityWithDictionary:record];
        [ret addObject:entity];
        for (id key in record) {
            id value = [entity objectForKey:key];
            if (value == Nil)
                continue;
            if ([key isEqualToString:@"image"]) {
                [queue addOperationWithBlock:^{
                    NSString *url = [self buildThumbUrlForEntity_:entity];
                    if (url)
                        [entity setObject:url forKey:@"image"];
                    else
                        [entity removeObjectForKey:@"image"];
                }];
                continue;
            }
        }
    }
    [queue waitUntilAllOperationsAreFinished];
    return ret;
}

- (NSString *)buildThumbUrlForEntity_:(ShotgunEntity *)entity
{
    NSString *path = [[NSString
                       stringWithFormat:@"/upload/get_thumbnail_url?entity_type=%@&entity_id=%@", 
                       [entity entityType], [entity entityId]]
                      stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    ShotgunRequest *request = 
        [ShotgunRequest shotgunRequestWithConfig:self.config path:path body:Nil headers:Nil andHTTPMethod:@"GET"];
    [request startSynchronous];
    NSString *body = [request response];
    NSArray *parts = [body componentsSeparatedByString:@"\n"];
    NSInteger code = [(NSString *)[parts objectAtIndex:0] integerValue];
    if (code == 0)
        NSLog(@"Error getting thumbnail url for entity %@ response was '%@'", entity, body);
    if (code == 1) {
        NSString *path = [parts objectAtIndex:1];
        if ([path length] == 0)
            return Nil;
        NSURL *url = [[[NSURL alloc] initWithScheme:self.config.scheme host:self.config.server path:[parts objectAtIndex:1]] autorelease];
        return [url absoluteString];
        
    }
    NSLog(@"Error getting thumbnail url: Unknown code %d %@", code, parts);
    return Nil;
}

-(NSArray *)listFromObj_:(id)obj
{
    return [self listFromObj_:obj withKeyName:@"field_name" andValueName:@"value"];       
}

- (NSArray *)listFromObj_:(id)obj withKeyName:(NSString *)keyName andValueName:(NSString *)valueName 
{
    NSMutableArray *ret = [NSMutableArray array];
    if (obj == Nil)
        return ret;
    id checkedObj = obj;
    if ([checkedObj isKindOfClass:[NSString class]])
        checkedObj = [(NSString *)obj JSONValue];
    if (![checkedObj isKindOfClass:[NSDictionary class]])
        [NSException raise:@"Value Error" format:@"Cannot interpret argument as a dictionary: %@", obj];
    for (id key in checkedObj)
        [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                            key, keyName,
                            [checkedObj objectForKey:key], valueName,
                        nil]];
    return ret;
}

- (NSDictionary *)buildPayloadWithConfig_:(ShotgunConfig *)config Method:(NSString *)method andParams:(NSDictionary *)params includeScriptName:(BOOL)includeScriptName
{
    NSMutableArray *callParams = [NSMutableArray array];
    if (includeScriptName) {
        NSMutableDictionary *authParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            config.scriptName, @"script_name",
                                            config.apiKey, @"script_key",
                                            nil];
        if (config.sessionUuid)
            [authParams setValue:config.sessionUuid forKey:@"session_uuid"];
        [callParams addObject:authParams];
    }
    if (params)
        [callParams addObject:params];
    NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
             method, @"method_name",
             callParams, @"params",
             nil];
    return ret;
}

- (id)transformOutboundData_:(id)data
{
    id(^outboundVisitor)(id) = ^(id value) {
        if ([value isKindOfClass:[NSDate class]]) {
            NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSString *ret = [formatter stringFromDate:value];
            return ret ? ret : value;
        }
        return value;
    };
    id ret = [self visitData_:data withVisitor:outboundVisitor];
    return ret;
}

- (id)transformInboundData_:(id)data
{
    id(^inboundVisitor)(id) = ^(id value) {
        if ([value isKindOfClass:[NSString class]]) {
            if([value length] == 20) {
                NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                NSDate *date = [formatter dateFromString:value];
                return date ? date : value;
            }
        }
        return value;
    };
    id ret = [self visitData_:data withVisitor:inboundVisitor];
    return ret;
}

- (id)visitData_:(id)data withVisitor:(id (^)(id))visitor
{
    if (data == Nil)
        return Nil;
    if ([data isKindOfClass:[NSArray class]]) {
        NSMutableArray *ret = [NSMutableArray array];
        for (id value in data)
            [ret addObject:[self visitData_:value withVisitor:visitor]];
        return ret;
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *ret = [NSMutableDictionary dictionary];
        for (id value in data)
            [ret setObject:[self visitData_:[data objectForKey:value] withVisitor:visitor]
                    forKey:value];
        return ret;
    }
    id ret = visitor(data);
    return ret;
}

@end
