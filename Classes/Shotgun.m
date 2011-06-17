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

@interface Shotgun()

- (ShotgunRequest *)_requestWithMethod:(NSString *)method andParams:(id)params;
- (ShotgunRequest *)_requestWithMethod:(NSString *)method params:(id)params includeScriptName:(BOOL)includeScriptName returnFirst:(BOOL)first;

- (id)_decodeResponseHeaders:(NSDictionary *)headers andBody:(NSString *)body;
- (void)_responseErrors:(id)response;

- (id)_transformInboundData:(id)data;
- (id)_transformOutboundData:(id)data;
- (id)_visitData:(id)data withVisitor:(id (^)(id))visitor;

- (NSDictionary *)_buildPayloadWithConfig:(ShotgunConfig *)config Method:(NSString *)method andParams:(NSDictionary *)params includeScriptName:(BOOL)includeScriptName;

- (NSString *)_getSessionToken;

- (NSArray *)_parseRecords:(id)records;
- (NSString *)_buildThumbUrlForEntity:(ShotgunEntity *)entity;

- (NSArray *)_listFromObj:(id)obj;
- (NSArray *)_listFromObj:(id)obj withKeyName:(NSString *)keyName andValueName:(NSString *)valueName;

@end

@implementation Shotgun

#pragma mark - Public Methods

- (id)initWithUrl:(NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key
{
    self = [super init];
    if (self) {
        _config = [[ShotgunConfig alloc] init];
        _config.apiKey = [[NSString alloc] initWithString:key];
        _config.scriptName = [[NSString alloc] initWithString:scriptName];
        NSURL *parseUrl = [NSURL URLWithString:[url lowercaseString]];
        _config.scheme = [parseUrl scheme];
        if (!([_config.scheme isEqualToString:@"http"] || [_config.scheme isEqualToString:@"https"]))
            [NSException raise:@"Invalid url" format:@"url must use http or https got '%@'", url];
        _config.server = [parseUrl host];
        NSString *apiBase = [parseUrl path];
        if ([apiBase isEqualToString:@""])
            _config.apiPath = [[NSString alloc] initWithFormat:@"/%@/json", _config.apiVer];
        else
            _config.apiPath = [[NSString alloc] initWithFormat:@"%@/%@/json", apiBase, _config.apiVer];
        
        // Get and check server capabilities
        ShotgunRequest *req = [self info];
        [req startSynchronous];
        NSDictionary *info = [req response];
        if (info)
            _serverCaps = [[ServerCapabilities alloc] initWithHost:_config.server andMeta:info];
        else
            return Nil;
        // Get and check client capabilities
        _clientCaps = [[ClientCapabilities alloc] init];
    }
    return self;
}

#pragma mark Query Information

- (ShotgunRequest *)info 
{
    return [self _requestWithMethod:@"info" params:Nil includeScriptName:NO returnFirst:NO];
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
        NSMutableDictionary *newFilters = [[[NSMutableDictionary alloc] init] autorelease];
        if ((filterOperator == Nil) || [filterOperator isEqualToString:@"all"])
            [newFilters setObject:@"and" forKey:@"logical_operator"];
        else
            [newFilters setObject:@"or" forKey:@"logical_operator"];
        
        NSMutableArray *conditions = [[[NSMutableArray alloc] init] autorelease];
        for (NSArray *filter in checkedFilters)
            [conditions addObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                                        [filter objectAtIndex:0], @"path",
                                        [filter objectAtIndex:1], @"relation",
                                        [filter subarrayWithRange:NSMakeRange(2, [filter count]-2)], @"values",
                                    nil] autorelease]];
        [newFilters setObject:conditions forKey:@"conditions"];
        checkedFilters = newFilters;
    } else if (filterOperator != Nil)
        [NSException raise:@"Shotgun Error" format:@"Use of filter_operator only valid when passing in an array filter."];
    
    // Defaults for fields
    if (checkedFields == Nil)
        checkedFields = [[[NSArray alloc] initWithObjects:@"id", nil] autorelease];
    
    // Type check variable typed arguments
    if (![checkedFilters isKindOfClass:[NSDictionary class]])
        [NSException raise:@"Value Error" format:@"Invalid filters: %@", filters];
    if (![checkedFields isKindOfClass:[NSArray class]])
        [NSException raise:@"Value Error" format:@"Invalid fields: %@", fields];
    if ((checkedOrder != Nil) && ![checkedOrder isKindOfClass:[NSArray class]])
        [NSException raise:@"Value Error" format:@"Invalid order: %@", order];
        
    // Inital parameters
    __block NSMutableDictionary *params = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        entityType, @"type",
                                        checkedFilters, @"filters",
                                        checkedFields, @"return_fields",
                                        retiredOnly ? @"retired" : @"active", @"return_only",
                                        [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                [[[NSNumber alloc] initWithUnsignedInteger:_config.recordsPerPage] autorelease], @"entities_per_page",
                                                [[[NSNumber alloc] initWithInt:1] autorelease], @"current_page",
                                          nil] autorelease], @"paging",
                                    nil] autorelease];
    
    if (_serverCaps.hasPaging)
        [params setObject:[NSNumber numberWithBool:YES] forKey:@"return_paging_info"];

    // Order
    if (checkedOrder != Nil) {
        NSMutableArray *sortList = [[[NSMutableArray alloc] init] autorelease];
        for (NSDictionary *sort in checkedOrder) {
            NSString *fieldName = [sort objectForKey:@"column"];
            if (fieldName == Nil)
                fieldName = [sort objectForKey:@"field_name"];
            NSString *direction = [sort objectForKey:@"direction"];
            if (direction == Nil)
                direction = @"asc";
            [sortList addObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                                        fieldName, @"field_name",
                                        direction, @"direction",
                                  nil] autorelease]];
        }
        [params setObject:sortList forKey:@"sorts"];
    }
    
    if (limit && limit <= _config.recordsPerPage) {
        [[params objectForKey:@"paging"] 
            setObject:[[[NSNumber alloc] initWithUnsignedInteger:limit] autorelease]
               forKey:@"entities_per_page"];
        if (page == 0)
            page = 1;
    }
    
    // Paging return
    if (page != 0) {
        if (_serverCaps.hasPaging)
            [params setObject:[NSNumber numberWithBool:NO] forKey:@"return_paging_info"];
        
        [[params objectForKey:@"paging"] 
                setObject:[[[NSNumber alloc] initWithUnsignedInteger:page] autorelease]
                   forKey:@"current_page"];
        ShotgunRequest *request = [self _requestWithMethod:@"read" andParams:params];
        ShotgunPostProcessBlock oldPost = [request postProcessBlock];
        [request setPostProcessBlock:^id (NSDictionary *headers, NSString *body) {
            NSArray *records = [oldPost(headers, body) objectForKey:@"entities"];
            if (records == Nil)
                records = [[[NSArray alloc] init] autorelease];
            return [self _parseRecords:records];
        }];
        return request;
    }
    
    // Get as many pages as needed
    ShotgunRequest *request = [self _requestWithMethod:@"read" andParams:params];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *headers, NSString *body) {
        NSDictionary *result = oldPost(headers, body);
        NSArray *entities = [result objectForKey:@"entities"];
        NSMutableArray *records = [[[NSMutableArray alloc] init] autorelease];
        NSArray *returnRecords = records;
        while (entities) {
            [records addObjectsFromArray:entities];
            if (limit && ([records count] >= limit)) {
                returnRecords = [[records subarrayWithRange:NSMakeRange(0, limit)] autorelease];
                break;
            }
            // result['paging_info']['entity_count'] == len(records)
            if ([[[result objectForKey:@"paging_info"] objectForKey:@"entity_count"] unsignedIntegerValue] == [records count])
                break;
            NSNumber *currentPage = [[params objectForKey:@"paging"] objectForKey:@"current_page"];
            NSNumber *nextPage = [[[NSNumber alloc] initWithUnsignedInteger:[currentPage unsignedIntegerValue]+1] autorelease];
            [[params objectForKey:@"paging"] setObject:nextPage forKey:@"current_page"];
            ShotgunRequest *nextPageRequest = [self _requestWithMethod:@"read" andParams:params];
            [nextPageRequest startSynchronous];
            result = [nextPageRequest response];
        }
        return [self _parseRecords:returnRecords];
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
        argFields = [[[NSArray alloc] initWithObjects:@"id", nil] autorelease];
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                [self _listFromObj:data], @"fields",
                                argFields, @"return_fields",
                             nil] autorelease];
    ShotgunRequest *request = [self _requestWithMethod:@"create" params:params includeScriptName:YES returnFirst:YES];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *requests, NSString *body) {
        id records = oldPost(requests, body);
        return [[self _parseRecords:records] objectAtIndex:0];
    }];
    return request;
}

- (ShotgunRequest *)updateEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId withData:(id)data
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                                [self _listFromObj:data], @"fields",
                             nil] autorelease];
    ShotgunRequest *request = [self _requestWithMethod:@"update" andParams:params];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *requests, NSString *body) {
        id records = oldPost(requests, body);
        return [[self _parseRecords:records] objectAtIndex:0];
    }];
    return request;
}

- (ShotgunRequest *)deleteEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                             nil] autorelease];
    return [self _requestWithMethod:@"delete" andParams:params];
}

- (ShotgunRequest *)reviveEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                             nil] autorelease];
    return [self _requestWithMethod:@"revive" andParams:params];
}

- (ShotgunRequest *)batch:(id)requests
{
    NSMutableArray *calls = [[[NSMutableArray alloc] init] autorelease];
    for (NSDictionary *request in requests) {
        NSString *requestType = [request objectForKey:@"request_type"];
        if ([requestType isEqualToString:@"create"]) {
            NSSet *requiredKeys = [[[NSSet alloc] initWithObjects:@"entity_type", @"data", nil] autorelease];
            if (![requiredKeys isSubsetOfSet:[NSSet setWithArray:[request allKeys]]])
                [NSException raise:@"Shotgun Error" format:@"Batch create request missing a required key: %@ (was %@)", requiredKeys, request];
            NSArray *returnFields = [request objectForKey:@"return_fields"];
            if (returnFields == Nil)
                returnFields = [[[NSArray alloc] initWithObjects:@"id", nil] autorelease];
            [calls addObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"create", @"request_type",
                                    [request objectForKey:@"entity_type"], @"type",
                                    [self _listFromObj:[request objectForKey:@"data"]], @"fields",
                                    returnFields, @"return_fields",
                               nil] autorelease]];
        } else if ([requestType isEqualToString:@"update"]) {
            NSSet *requiredKeys = [[[NSSet alloc] initWithObjects:@"entity_type", @"entity_id", @"data", nil] autorelease];
            if (![requiredKeys isSubsetOfSet:[NSSet setWithArray:[request allKeys]]])
                [NSException raise:@"Shotgun Error" format:@"Batch update request missing a required key: %@ (was %@)", requiredKeys, request];
            [calls addObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"update", @"request_type",
                                    [request objectForKey:@"entity_type"], @"type",
                                    [request objectForKey:@"entity_id"], @"id",
                                    [self _listFromObj:[request objectForKey:@"data"]], @"fields",
                               nil] autorelease]];
        } else if ([requestType isEqualToString:@"delete"]) {
            NSSet *requiredKeys = [[[NSSet alloc] initWithObjects:@"entity_type", @"entity_id", nil] autorelease];
            if (![requiredKeys isSubsetOfSet:[NSSet setWithArray:[request allKeys]]])
                [NSException raise:@"Shotgun Error" format:@"Batch delete request missing a required key: %@ (was %@)", requiredKeys, request];
            [calls addObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"delete", @"request_type",
                                    [request objectForKey:@"entity_type"], @"type",
                                    [request objectForKey:@"entity_id"], @"id",
                               nil] autorelease]];
        } else {
            [NSException raise:@"Shotgun Error" format:@"Invalid requestType '%@' for batch", requestType];
        }
    }
    ShotgunRequest *request = [self _requestWithMethod:@"batch" andParams:calls];
    ShotgunPostProcessBlock oldPost = [request postProcessBlock];
    [request setPostProcessBlock:^id (NSDictionary *requests, NSString *body) {
        id records = oldPost(requests, body);
        return [self _parseRecords:records];
    }];
    return request;
}

#pragma mark Meta Schema

- (ShotgunRequest *)schemaEntityRead
{
    return [self _requestWithMethod:@"schema_entity_read" andParams:Nil];
}

- (ShotgunRequest *)schemaRead 
{
    return [self _requestWithMethod:@"schema_read" andParams:Nil];
}

- (ShotgunRequest *)schemaFieldReadForEntityOfType:(NSString *)entityType 
{
    return [self schemaFieldReadForEntityOfType:entityType forField:Nil];
}

- (ShotgunRequest *)schemaFieldReadForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName 
{
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:entityType, @"type", nil] autorelease];
    if (fieldName != Nil)
        [params setObject:fieldName forKey:@"field_name"];
    return [self _requestWithMethod:@"schema_field_read" andParams:params];
}

- (ShotgunRequest *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType 
                               withDisplayName:(NSString *)displayName
{
    return [self schemaFieldCreateForEntityOfType:entityType ofDataType:dataType withDisplayName:displayName andProperties:Nil];
}

- (ShotgunRequest *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType
                               withDisplayName:(NSString *)displayName andProperties:(id)properties
{
    NSMutableArray *propertiesParam = [[[NSMutableArray alloc] initWithObjects:
                                            [[[NSDictionary alloc] initWithObjectsAndKeys:
                                                    @"name", @"property_name",
                                                    displayName, @"value",
                                              nil] autorelease],
                                        nil] autorelease];
    [propertiesParam addObjectsFromArray:[self _listFromObj:properties
                                                 withKeyName:@"property_name"
                                                andValueName:@"value"]];
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                dataType, @"data_type",
                                propertiesParam, @"properties",
                             nil] autorelease];
    return [self _requestWithMethod:@"schema_field_create" andParams:params];
}

- (ShotgunRequest *)schemaFieldUpdateForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName withProperties:(NSDictionary *)properties
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                fieldName, @"field_name",
                                [self _listFromObj:properties withKeyName:@"property_name" andValueName:@"value"], @"properties",
                            nil] autorelease];
    return [self _requestWithMethod:@"schema_field_update" andParams:params];
}

- (ShotgunRequest *)schemaFieldDeleteForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName 
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                fieldName, @"field_name",
                             nil] autorelease];
    return [self _requestWithMethod:@"schema_field_delete" andParams:params];
}

- (void)setSessionUuid:(NSString *)uuid
{
    _config.sessionUuid = uuid;
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
        url = [[NSURL alloc] initWithScheme:_config.scheme host:_config.server path:@"/upload/publish_thumbnail"];
        request = [ASIFormDataRequest requestWithURL:url];
        [url release];
        [request setFile:path forKey:@"thumb_image"];
    } else {
        url = [[NSURL alloc] initWithScheme:_config.scheme host:_config.server path:@"/upload/upload_file"];
        request = [ASIFormDataRequest requestWithURL:url];
        [url release];
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
    [request setPostValue:_config.scriptName forKey:@"script_name"];
    [request setPostValue:_config.apiKey forKey:@"script_key"];
    if (_config.sessionUuid != Nil)
        [request setPostValue:_config.sessionUuid forKey:@"session_uuid"];

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

    NSNumber *resultId = [[[NSNumber alloc] initWithInt:0] autorelease];
    return resultId;
}

- (NSData *)downloadAttachmentWithId:(NSNumber *)attachmentId
{
    NSString *sessionId = [self _getSessionToken];
    
    NSString *path = [[NSString alloc] initWithFormat:@"/file_serve/%@", attachmentId];
    NSURL *url = [[NSURL alloc] initWithScheme:_config.scheme host:_config.server path:path];
    [path release];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [url release];
    [request setUserAgent:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; " \
        "rv:1.9.0.7) Gecko/2009021906 Firefox/3.0.7"];
    NSDictionary *properties = [[[NSMutableDictionary alloc] init] autorelease];
    [properties setValue:@"0" forKey:NSHTTPCookieVersion];
    [properties setValue:@"_session_id" forKey:NSHTTPCookieName];
    [properties setValue:sessionId forKey:NSHTTPCookieValue];
    [properties setValue:_config.server forKey:NSHTTPCookieDomain];
    [properties setValue:@"/" forKey:NSHTTPCookiePath];
    NSHTTPCookie *cookie = [[[NSHTTPCookie alloc] initWithProperties:properties] autorelease];
    [request setUseCookiePersistence:NO];
    [request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
    [request startSynchronous];
    NSError *error = [request error];
    if (error)
        [NSException raise:@"Shotgun Error" format:@"Failed to open %@, with code: %@ and message %@",
         url, [error code], [error description]];
    return [request responseData];
}

#pragma mark - Destruction

- (void)dealloc 
{
    [_clientCaps release];
    [_serverCaps release];
    [_config release];
    [super dealloc];
}

#pragma mark - Private Category Methods

- (id)_decodeResponseHeaders:(NSDictionary *)headers andBody:(NSString *)body
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

- (void)_responseErrors:(id)response
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

- (NSString *)_getSessionToken {
    if (_config.sessionToken != Nil)
        return _config.sessionToken;
    
    ShotgunRequest *request = [self _requestWithMethod:@"get_session_token" andParams:Nil];
    [request startSynchronous];
    NSDictionary *results = [request response];
    NSString *sessionToken = [results objectForKey:@"session_id"];
    if (sessionToken == Nil)
        [NSException raise:@"Shotgun Error" format:@"Could not extract session_id from %@", results];
    _config.sessionToken = sessionToken;
    return _config.sessionToken;
}

- (ShotgunRequest *)_requestWithMethod:(NSString *)method andParams:(id)params
{
    return [self _requestWithMethod:method params:params includeScriptName:YES returnFirst:NO];
}

- (ShotgunRequest *)_requestWithMethod:(NSString *)method params:(id)params includeScriptName:(BOOL)includeScriptName returnFirst:(BOOL)first
{
    NSDictionary *paramsTransformed = [self _transformOutboundData:params];
    NSDictionary *payload = [self _buildPayloadWithConfig:_config Method:method andParams:paramsTransformed includeScriptName:includeScriptName];
    NSString *encodedPayload = [payload JSONRepresentation];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"content-type"];
    
    ShotgunRequest *request = 
        [[[ShotgunRequest alloc] initWithConfig:_config 
                                           path:_config.apiPath
                                           body:encodedPayload 
                                        headers:headers andHTTPMethod:@"POST"] autorelease];
    [request setPostProcessBlock:^id (NSDictionary *headers, NSString *body) {
        // Parse the results
        id response = [self _decodeResponseHeaders:headers andBody:body];
        [self _responseErrors:response];
        id transformedResponse = [self _transformInboundData:response];
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

- (NSArray *)_parseRecords:(id)records 
{
    NSMutableArray *ret = [[[NSMutableArray alloc] init] autorelease];
    if (records == Nil)
        return ret;
    NSArray *iteratee;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:5];
    queue.name = @"Thumbnail Converting Queue";
    NSLog(@"Converting thumbs on queue: %@", queue.name);
    if (![records isKindOfClass:[NSArray class]])
        iteratee = [[[NSArray alloc] initWithObjects:records, nil] autorelease];
    else
        iteratee = records;
    for (id record in iteratee) {
        if (![record isKindOfClass:[NSDictionary class]]) {
            [ret addObject:record];
            continue;
        }
        ShotgunEntity *entity = [[[ShotgunEntity alloc] initWithDictionary:record] autorelease];
        [ret addObject:entity];
        for (id key in record) {
            id value = [entity objectForKey:key];
            if (value == Nil)
                continue;
            if ([key isEqualToString:@"image"]) {
                [queue addOperationWithBlock:^{
                    NSString *url = [self _buildThumbUrlForEntity:entity];
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
    [queue release];
    return ret;
}

- (NSString *)_buildThumbUrlForEntity:(ShotgunEntity *)entity
{
    NSString *path = [[NSString
                       stringWithFormat:@"/upload/get_thumbnail_url?entity_type=%@&entity_id=%@", 
                       [entity entityType], [entity entityId]]
                      stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    ShotgunRequest *request = 
        [[[ShotgunRequest alloc] initWithConfig:_config path:path body:Nil headers:Nil andHTTPMethod:@"GET"] autorelease];
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
        NSURL *url = [[[NSURL alloc] initWithScheme:_config.scheme host:_config.server path:[parts objectAtIndex:1]] autorelease];
        return [url absoluteString];
        
    }
    NSLog(@"Error getting thumbnail url: Unknown code %d %@", code, parts);
    return Nil;
}

-(NSArray *)_listFromObj:(id)obj
{
    return [self _listFromObj:obj withKeyName:@"field_name" andValueName:@"value"];       
}

- (NSArray *)_listFromObj:(id)obj withKeyName:(NSString *)keyName andValueName:(NSString *)valueName 
{
    NSMutableArray *ret = [[[NSMutableArray alloc] init] autorelease];
    if (obj == Nil)
        return ret;
    id checkedObj = obj;
    if ([checkedObj isKindOfClass:[NSString class]])
        checkedObj = [(NSString *)obj JSONValue];
    if (![checkedObj isKindOfClass:[NSDictionary class]])
        [NSException raise:@"Value Error" format:@"Cannot interpret argument as a dictionary: %@", obj];
    for (id key in checkedObj)
        [ret addObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                            key, keyName,
                            [checkedObj objectForKey:key], valueName,
                        nil] autorelease]];
    return ret;
}

- (NSDictionary *)_buildPayloadWithConfig:(ShotgunConfig *)config Method:(NSString *)method andParams:(NSDictionary *)params includeScriptName:(BOOL)includeScriptName
{
    NSMutableArray *callParams = [[[NSMutableArray alloc] init] autorelease];
    if (includeScriptName) {
        NSMutableDictionary *authParams = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                            config.scriptName, @"script_name",
                                            config.apiKey, @"script_key",
                                            nil] autorelease];
        if (config.sessionUuid)
            [authParams setValue:config.sessionUuid forKey:@"session_uuid"];
        [callParams addObject:authParams];
    }
    if (params)
        [callParams addObject:params];
    
    return [[[NSDictionary alloc] initWithObjectsAndKeys:
             method, @"method_name",
             callParams, @"params",
             nil] autorelease];
}

- (id)_transformOutboundData:(id)data
{
    id(^outboundVisitor)(id) = ^(id value) {
        if ([value isKindOfClass:[NSDate class]]) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSString *ret = [formatter stringFromDate:value];
            [formatter release];
            return ret ? ret : value;
        }
        return value;
    };
    return [self _visitData:data withVisitor:outboundVisitor];
}

- (id)_transformInboundData:(id)data
{
    id(^inboundVisitor)(id) = ^(id value) {
        if ([value isKindOfClass:[NSString class]]) {
            if([value length] == 20) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                NSDate *date = [formatter dateFromString:value];
                [formatter release];
                return date ? date : value;
            }
        }
        return value;
    };
    return [self _visitData:data withVisitor:inboundVisitor];
}

- (id)_visitData:(id)data withVisitor:(id (^)(id))visitor
{
    if (data == Nil)
        return Nil;
    if ([data isKindOfClass:[NSArray class]]) {
        NSMutableArray *ret = [[[NSMutableArray alloc] init] autorelease];
        for (id value in data)
            [ret addObject:[self _visitData:value withVisitor:visitor]];
        return ret;
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *ret = [[[NSMutableDictionary alloc] init] autorelease];
        for (id value in data)
            [ret setObject:[self _visitData:[data objectForKey:value] 
                                withVisitor:visitor]
                    forKey:value];
        return ret;
    }
    return visitor(data);
}

@end
