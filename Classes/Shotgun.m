//
//  Shotgun.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//
//  TODO: Implement Authentication
//  TODO: Switch to returning ShotgunRequest objects for async
//  TODO: Figure out a way to do image url lookup in the background

#import "SBJson.h"
#import "ASIFormDataRequest.h"
#import "Config.h"
#import "ServerCapabilities.h"
#import "ClientCapabilities.h"
#import "Shotgun.h"

@implementation Shotgun

#pragma mark - Public Methods

- (id)initWithUrl: (NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key {
    return [self initWithUrl:url scriptName:scriptName andKey:key andConvertDatetimesToUTC:YES];
}

- (id)initWithUrl: (NSString *)url scriptName:(NSString *)scriptName 
           andKey:(NSString *)key andConvertDatetimesToUTC:(BOOL)convertDatetimesToUTC
{
    self = [super init];
    if (self) {
        myConfig = [[Config alloc] init];
        myConfig.apiKey = [[NSString alloc] initWithString:key];
        myConfig.scriptName = [[NSString alloc] initWithString:scriptName];
        myConfig.convertDatetimesToUTC = convertDatetimesToUTC;
        NSURL *parseUrl = [NSURL URLWithString:[url lowercaseString]];
        myConfig.scheme = [parseUrl scheme];
        if (!([myConfig.scheme isEqualToString:@"http"] || [myConfig.scheme isEqualToString:@"https"]))
            [NSException raise:@"Invalid url" format:@"url must use http or https got '%@'", url];
        myConfig.server = [parseUrl host];
        NSString *apiBase = [parseUrl path];
        if ([apiBase isEqualToString:@""])
            myConfig.apiPath = [[NSString alloc] initWithFormat:@"/%@/json", myConfig.apiVer];
        else
            myConfig.apiPath = [[NSString alloc] initWithFormat:@"%@/%@/json", apiBase, myConfig.apiVer];
        
        myClientCaps = [[ClientCapabilities alloc] init];
        myServerCaps = [[ServerCapabilities alloc] initWithHost:myConfig.server andMeta:[self info]];
    }
    return self;
}

#pragma mark Query Information
- (NSDictionary *)info 
{
    return [self _callRpcWithMethod:@"info" andParams:Nil includeScriptName:NO returnFirst:NO];
}

- (NSDictionary *)findEntityOfType: (NSString *)entityType withFilters:(id)filters
{
    return [self findEntityOfType:entityType withFilters:filters andFields:Nil];
}

- (NSDictionary *)findEntityOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
{
    return [self findEntityOfType:entityType withFilters:filters andFields:fields andOrder:Nil andFilterOperator:Nil retiredOnly:NO];
}

- (NSDictionary *)findEntityOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                          andOrder:(id)order andFilterOperator:(NSString *)filterOperator retiredOnly:(BOOL)retiredOnly
{
    NSArray *results = [self findEntitiesOfType:entityType withFilters:filters andFields:fields andOrder:order 
                              andFilterOperator:filterOperator andLimit:1 andPage:0 retiredOnly:retiredOnly];
    if ([results count] > 0)
        return [results objectAtIndex:0];
    return Nil;
}

- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters
{
    return [self findEntitiesOfType:entityType withFilters:filters andFields:Nil];
}

- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
{
    return [self findEntitiesOfType:entityType withFilters:filters andFields:fields 
                           andOrder:Nil andFilterOperator:Nil andLimit:0 andPage:0 retiredOnly:NO];
}

- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator
{
    return [self findEntitiesOfType:entityType withFilters:filters andFields:fields 
                           andOrder:order andFilterOperator:filterOperator andLimit:0 andPage:0 retiredOnly:NO];
}
            
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
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
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        entityType, @"type",
                                        checkedFilters, @"filters",
                                        checkedFields, @"return_fields",
                                        retiredOnly ? @"retired" : @"active", @"return_only",
                                        [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                [[[NSNumber alloc] initWithUnsignedInteger:myConfig.recordsPerPage] autorelease], @"entities_per_page",
                                                [[[NSNumber alloc] initWithInt:1] autorelease], @"current_page",
                                          nil] autorelease], @"paging",
                                    nil] autorelease];
    
    if (myServerCaps.hasPaging)
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
    
    if (limit && limit <= myConfig.recordsPerPage) {
        [[params objectForKey:@"paging"] 
            setObject:[[[NSNumber alloc] initWithUnsignedInteger:limit] autorelease]
               forKey:@"entities_per_page"];
        if (page == 0)
            page = 1;
    }
    
    // Paging return
    if (page != 0) {
        if (myServerCaps.hasPaging)
            [params setObject:[NSNumber numberWithBool:NO] forKey:@"return_paging_info"];
        
        [[params objectForKey:@"paging"] 
                setObject:[[[NSNumber alloc] initWithUnsignedInteger:page] autorelease]
                   forKey:@"current_page"];
        NSArray *records = [[self _callRpcWithMethod:@"read" andParams:params] objectForKey:@"entities"];
        if (records == Nil)
            records = [[[NSArray alloc] init] autorelease];
        return [self _parseRecords:records];
    }
    
    // Get as many pages as needed
    NSArray *entities;
    NSMutableArray *records = [[[NSMutableArray alloc] init] autorelease];
    NSArray *returnRecords = records;
    NSDictionary *result = [self _callRpcWithMethod:@"read" andParams:params];
    entities = [result objectForKey:@"entities"];
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
        NSNumber *nextPage = [[[NSNumber alloc] initWithUnsignedInteger:[currentPage unsignedIntegerValue]+1] autorelease];
        [[params objectForKey:@"paging"] setObject:nextPage forKey:@"current_page"];
        result = [self _callRpcWithMethod:@"read" andParams:params];
    }
    return [self _parseRecords:returnRecords];
}

#pragma mark Modify Information
- (NSDictionary *)createEntityOfType: (NSString *)entityType withData:(id)data
{
    return [self createEntityOfType:entityType withData:data returnFields:Nil];
}

- (NSDictionary *)createEntityOfType: (NSString *)entityType withData:(id)data returnFields:(id)returnFields
{
    NSArray *argFields = returnFields;
    if (argFields == Nil)
        argFields = [[[NSArray alloc] initWithObjects:@"id", nil] autorelease];
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                [self _listFromObj: data], @"fields",
                                argFields, @"return_fields",
                             nil] autorelease];
    NSDictionary *record = [self _callRpcWithMethod:@"create" andParams:params includeScriptName:YES returnFirst:YES];
    return [[self _parseRecords:record] objectAtIndex:0];
}

- (NSDictionary *)updateEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId withData:(id)data
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                                [self _listFromObj: data], @"fields",
                             nil] autorelease];
    NSDictionary *record = [self _callRpcWithMethod:@"update" andParams:params];
    return [[self _parseRecords:record] objectAtIndex:0];
}

- (BOOL)deleteEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                             nil] autorelease];
    return [(NSNumber *)[self _callRpcWithMethod:@"delete" andParams:params] boolValue];
}

- (BOOL)reviveEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                entityId, @"id",
                             nil] autorelease];
    return [(NSNumber *)[self _callRpcWithMethod:@"revive" andParams:params] boolValue];
}

- (NSArray *)batch:(id)requests
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
    id records = [self _callRpcWithMethod:@"batch" andParams:calls];
    return [self _parseRecords:records];
}

#pragma mark Meta Schema
- (NSDictionary *)schemaEntityRead
{
    return [self _callRpcWithMethod:@"schema_entity_read" andParams:Nil];
}

- (NSDictionary *)schemaRead 
{
    return [self _callRpcWithMethod:@"schema_read" andParams:Nil];
}

- (NSDictionary *)schemaFieldReadForEntityOfType: (NSString *)entityType 
{
    return [self schemaFieldReadForEntityOfType:entityType forField:Nil];
}

- (NSDictionary *)schemaFieldReadForEntityOfType: (NSString *)entityType forField:(NSString *)fieldName 
{
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:entityType, @"type", nil] autorelease];
    if (fieldName != Nil)
        [params setObject:fieldName forKey:@"field_name"];
    return [self _callRpcWithMethod:@"schema_field_read" andParams:params];
}

- (NSString *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType 
                               withDisplayName:(NSString *)displayName
{
    return [self schemaFieldCreateForEntityOfType:entityType ofDataType:dataType withDisplayName:displayName andProperties:Nil];
}

- (NSString *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType
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
    return (NSString *)[self _callRpcWithMethod:@"schema_field_create" andParams:params];
}

- (BOOL)schemaFieldUpdateForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName withProperties:(NSDictionary *)properties
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                fieldName, @"field_name",
                                [self _listFromObj:properties withKeyName:@"property_name" andValueName:@"value"], @"properties",
                            nil] autorelease];
    return [(NSNumber *)[self _callRpcWithMethod:@"schema_field_update" andParams:params] boolValue];
}

- (BOOL)schemaFieldDeleteForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName 
{
    NSDictionary *params = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                entityType, @"type",
                                fieldName, @"field_name",
                             nil] autorelease];
    return [(NSNumber *)[self _callRpcWithMethod:@"schema_field_delete" andParams:params] boolValue];    
}

- (void)setSessionUuid:(NSString *)uuid
{
    myConfig.sessionUuid = uuid;
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

- (NSNumber *)uploadForEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path forField:(NSString *)fieldName
                    withDisplayName:(NSString *)displayName andTagList:(NSString *)tagList
{
    path = [path stringByExpandingTildeInPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        [NSException raise:@"Value Error" format:@"Path must be a valid file, got '%@'", path];
    
    BOOL isThumbnail = [fieldName isEqualToString:@"thumb_image"];

    NSURL *url;
    ASIFormDataRequest *request;
    if (isThumbnail) {
        url = [[NSURL alloc] initWithScheme:myConfig.scheme host:myConfig.server path:@"/upload/publish_thumbnail"];
        request = [ASIFormDataRequest requestWithURL:url];
        [url release];
        [request setFile:path forKey:@"thumb_image"];
    } else {
        url = [[NSURL alloc] initWithScheme:myConfig.scheme host:myConfig.server path:@"/upload/upload_file"];
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
    [request setPostValue:myConfig.scriptName forKey:@"script_name"];
    [request setPostValue:myConfig.apiKey forKey:@"script_key"];
    if (myConfig.sessionUuid != Nil)
        [request setPostValue:myConfig.sessionUuid forKey:@"session_uuid"];

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

- (NSData *)downloadAttachmentWithId: (NSNumber *)attachmentId
{
    NSString *sessionId = [self _getSessionToken];
    
    NSString *path = [[NSString alloc] initWithFormat:@"/file_serve/%@", attachmentId];
    NSURL *url = [[NSURL alloc] initWithScheme:myConfig.scheme host:myConfig.server path:path];
    [path release];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [url release];
    [request setUserAgent:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; " \
        "rv:1.9.0.7) Gecko/2009021906 Firefox/3.0.7"];
    NSDictionary *properties = [[[NSMutableDictionary alloc] init] autorelease];
    [properties setValue:@"0" forKey:NSHTTPCookieVersion];
    [properties setValue:@"_session_id" forKey:NSHTTPCookieName];
    [properties setValue:sessionId forKey:NSHTTPCookieValue];
    [properties setValue:myConfig.server forKey:NSHTTPCookieDomain];
    [properties setValue:@"/" forKey:NSHTTPCookiePath];
    NSHTTPCookie *cookie = [[[NSHTTPCookie alloc] initWithProperties:properties] autorelease];
    [request setUseCookiePersistence:NO];
    [request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
    [request startSynchronous];
    NSError *error = [request error];
    if (error)
        [NSException raise:@"Shotgun Error" format:@"Failed to open %@, with code: %@ and message %@",
         url, [request responseStatusCode], [request responseStatusMessage]];
    return [request responseData];
}

#pragma mark - Destruction

- (void)dealloc 
{
    [myClientCaps release];
    [myServerCaps release];
    [myConfig release];
    [super dealloc];
}

#pragma mark - Internal Methods

- (NSString *)_getSessionToken {
    if (myConfig.sessionToken != Nil)
        return myConfig.sessionToken;
    
    NSDictionary *results = [self _callRpcWithMethod:@"get_session_token" andParams:Nil];
    NSString *sessionToken = [results objectForKey:@"session_id"];
    if (sessionToken == Nil)
        [NSException raise:@"Shotgun Error" format:@"Could not extract session_id from %@", results];
    myConfig.sessionToken = sessionToken;
    return myConfig.sessionToken;
}

- (NSDictionary *)_callRpcWithMethod: (NSString *)method andParams:(id)params
{
    return [self _callRpcWithMethod:method andParams:params includeScriptName:YES returnFirst:NO];
}

- (NSDictionary *)_callRpcWithMethod: (NSString *)method andParams:(NSDictionary *)params 
                   includeScriptName:(BOOL) includeScriptName returnFirst:(BOOL)first
{
    NSLog(@"Starting rpc call to %@ with params %@", method, params);
    NSDictionary *paramsTransformed = [self _transformOutboundWithData: params];
    NSDictionary *payload = [self _buildPayloadWithMethod:method andParams:paramsTransformed includeScriptName:includeScriptName];
    NSString *encodedPayload = [self _encodePayload: payload];
    NSDictionary *reqHeaders = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"content-type", @"application/json; charset=utf-8",
                                nil];
    // Make the request
    NSInteger responseStatus;
    NSDictionary *responseHeaders;
    NSString *responseBody;
    [self _makeCallWithPath:myConfig.apiPath 
                    andBody:encodedPayload 
                 andHeaders:reqHeaders andHTTPMethod:@"POST" 
             responseStatus:&responseStatus 
            responseHeaders:&responseHeaders 
               responseBody:&responseBody];
    NSLog(@"Completed rpc call to %@", method);
    if (responseStatus > 300)
        [NSException raise:@"HTTP Error" 
                    format:@"HTTP Error from server %d %@", responseStatus, [NSHTTPURLResponse localizedStringForStatusCode:responseStatus]];
    id response = [self _decodeResponseWithHeaders:responseHeaders andBody:responseBody];
    [self _responseErrors: response];
    id transformedResponse = [self _transformInboundWithData:response];
    
    if ([transformedResponse isKindOfClass:[NSDictionary class]]) {
        id results = [(NSDictionary *)transformedResponse objectForKey:@"results"];
        if (results == Nil)
            return transformedResponse;
        if (first && [results isKindOfClass:[NSArray class]])
            return [(NSArray *)results objectAtIndex:0];
        return results;
    }
    return transformedResponse;    
}

- (id)_visitData:(id)data withVisitor:(id (^)(id))visitor {
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

- (id)_transformOutboundWithData: (id)data
{
    id(^outboundVisitor)(id) = ^(id value) {
        if ([value isKindOfClass:[NSDate class]]) {
            if (!myConfig.convertDatetimesToUTC) {
                // We are not converting to UTC, assume that NSDates are in the local
                // timezone.  Without timezone aware objects, this'll have to do.
                NSTimeZone* local = [NSTimeZone localTimeZone];
                NSTimeZone* utc = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                
                NSInteger sourceGMTOffset = [local secondsFromGMTForDate:value];
                NSInteger destinationGMTOffset = [utc secondsFromGMTForDate:value];
                NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
                value = [[[NSDate alloc] initWithTimeInterval:interval sinceDate:value] autorelease];
            }
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

- (id)_transformInboundWithData:(id)data
{
    id(^inboundVisitor)(id) = ^(id value) {
        NSLog(@"inboundVisitor: %@", value);
        if ([value isKindOfClass:[NSString class]]) {
            if([value length] == 20) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                if (myConfig.convertDatetimesToUTC)
                    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                NSDate *date = [formatter dateFromString:value];
                [formatter release];
                NSLog(@"STR: %@ to date %@", value, date);
                return date ? date : value;
            }
        }
        return value;
    };
    return [self _visitData:data withVisitor:inboundVisitor];}

- (NSDictionary *)_buildPayloadWithMethod: (NSString *)method andParams:(NSDictionary *)params includeScriptName:(BOOL)includeScriptName
{
    NSMutableArray *callParams = [[[NSMutableArray alloc] init] autorelease];
    if (includeScriptName) {
        NSMutableDictionary *authParams = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                myConfig.scriptName, @"script_name",
                                                myConfig.apiKey, @"script_key",
                                           nil] autorelease];
        if (myConfig.sessionUuid)
            [authParams setValue:myConfig.sessionUuid forKey:@"session_uuid"];
        [callParams addObject:authParams];
    }
    if (params)
        [callParams addObject:params];
    
    return [[[NSDictionary alloc] initWithObjectsAndKeys:
                method, @"method_name",
                callParams, @"params",
            nil] autorelease];
}

- (NSString *)_encodePayload: (NSDictionary *)payload 
{
    return [payload JSONRepresentation];
}

- (id)_decodeResponseWithHeaders: (NSDictionary *)headers andBody:(NSString *)body
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

- (void)_makeCallWithPath: (NSString *)path andBody:(NSString *)body andHeaders:(NSDictionary *)headers andHTTPMethod:(NSString *)method
           responseStatus:(NSInteger *)responseStatus responseHeaders:(NSDictionary **)responseHeaders responseBody:(NSString **)responseBody
{
    NSMutableDictionary *reqHeaders = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    @"shotgun-json", @"user-agent",
                                nil] autorelease];
    [reqHeaders addEntriesFromDictionary:headers];
    NSURL *url = [[NSURL alloc] initWithScheme:myConfig.scheme host:myConfig.server path:path];
    NSLog(@"Request is %@:%@", method, url);
    NSLog(@"Request headers are %@", headers);
    NSLog(@"Request body is %@", body);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:myConfig.timeoutSecs];
    [url release];
    [request setHTTPMethod:method];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setAllHTTPHeaderFields:headers];
    int attempt = 0;
    NSError *error = Nil;
    while (attempt < myConfig.maxRpcAttempts) {
        attempt += 1;
        NSHTTPURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (data == Nil)
            continue;
        NSString *tmpResponseBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSInteger tmpResponseStatus = [response statusCode];
        NSDictionary *tmpResponseHeaders = [response allHeaderFields];
        NSLog(@"Response status is %d %@", tmpResponseStatus, [NSHTTPURLResponse localizedStringForStatusCode:tmpResponseStatus]);
        NSLog(@"Response headers are %@", tmpResponseHeaders);
        NSLog(@"Response body is %@", tmpResponseBody);
        if (responseBody)
            *responseBody = tmpResponseBody;
        if (responseStatus)
            *responseStatus = [response statusCode];
        if (responseHeaders)
            *responseHeaders = [response allHeaderFields];
        return;
    }
    [NSException raise:@"Unable to connect" format:@"%@. %@", [error localizedDescription], [error localizedFailureReason]];
}

- (NSArray *)_parseRecords:(id)records 
{
    NSMutableArray *ret = [[[NSMutableArray alloc] init] autorelease];
    if (records == Nil)
        return ret;
    NSArray *iteratee;
    if (![records isKindOfClass:[NSArray class]])
        iteratee = [[[NSArray alloc] initWithObjects:records, nil] autorelease];
    else
        iteratee = records;
    for (id record in iteratee) {
        if (![record isKindOfClass:[NSDictionary class]]) {
            [ret addObject:record];
            continue;
        }
        NSMutableDictionary *mutieDict = [[[NSMutableDictionary alloc] initWithDictionary:record] autorelease];
        [ret addObject:mutieDict];
        for (id key in record) {
            id value = [mutieDict objectForKey:key];
            if (value == Nil)
                continue;
            if ([key isEqualToString:@"image"]) {
                [mutieDict setValue:[self _buildThumbUrlForEntityOfType:[record objectForKey:@"type"] andId:[record objectForKey:@"id"]]
                             forKey:@"image"];
                continue;
            }
        }
    }
    return ret;
}

- (NSString *)_buildThumbUrlForEntityOfType: (NSString *)entityType andId:(NSNumber *)entityId 
{
    NSString *path = [[[[NSString alloc] 
                        initWithFormat:@"/upload/get_thumbnail_url?entity_type=%@&entity_id=%@",
                            entityType, entityId] autorelease]
                     stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *body = Nil;
    [self _makeCallWithPath:path andBody:Nil andHeaders:Nil andHTTPMethod:@"GET" responseStatus:Nil responseHeaders:Nil responseBody:&body];
    NSArray *parts = [body componentsSeparatedByString:@"\n"];
    NSInteger code = [(NSString *)[parts objectAtIndex:0] integerValue];
    if (code == 0)
        [NSException raise:@"Error getting thumbnail url" format:@"%@", [parts objectAtIndex:1]];
    if (code == 1) {
        NSString *path = [parts objectAtIndex:1];
        if ([path length] == 0)
            return Nil;
        NSURL *url = [[[NSURL alloc] initWithScheme:myConfig.scheme host:myConfig.server path:[parts objectAtIndex:1]] autorelease];
        return [url absoluteString];
        
    }
    [NSException raise:@"Error getting thumbnail url" format:@"Unknown code %d %@", code, [parts objectAtIndex:1]];
    return (NSString *)-1;
}

-(NSArray *)_listFromObj: (id)obj
{
    return [self _listFromObj:obj withKeyName:@"field_name" andValueName:@"value"];       
}

- (NSArray *)_listFromObj: (id)obj withKeyName: (NSString *)keyName andValueName: (NSString *)valueName 
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

@end
