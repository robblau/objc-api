//
//  Shotgun.h
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Config;
@class ServerCapabilities;
@class ClientCapabilities;

@interface Shotgun : NSObject {
@private
    Config *myConfig;
    ServerCapabilities *myServerCaps;
    ClientCapabilities *myClientCaps;
}

#pragma mark -
#pragma mark Public Methods

- (id)initWithUrl: (NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key;
- (id)initWithUrl: (NSString *)url scriptName:(NSString *)scriptName
           andKey:(NSString *)key andConvertDatetimesToUTC:(BOOL)convertDatetimesToUTC;

#pragma mark Query Information
- (NSDictionary *)info;
- (NSDictionary *)findEntityOfType: (NSString *)entityType withFilters:(id)filters;
- (NSDictionary *)findEntityOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields;
- (NSDictionary *)findEntityOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                          andOrder:(id)order andFilterOperator:(NSString *)filterOperator retiredOnly:(BOOL)retiredOnly;
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters;
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields;
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator;
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator andLimit:(NSUInteger)limit
                        andPage:(NSUInteger)page retiredOnly:(BOOL)retiredOnly;

#pragma mark Modify Information
- (NSDictionary *)createEntityOfType: (NSString *)entityType withData:(id)data;
- (NSDictionary *)createEntityOfType: (NSString *)entityType withData:(id)data returnFields:(id)returnFields;
- (NSDictionary *)updateEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId withData:(id)data;
- (BOOL)deleteEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId;
- (BOOL)reviveEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId;
- (NSArray *)batch: (id)requests;

#pragma mark Meta Schema
- (NSDictionary *)schemaEntityRead;
- (NSDictionary *)schemaRead;
- (NSDictionary *)schemaFieldReadForEntityOfType: (NSString *)entityType;
- (NSDictionary *)schemaFieldReadForEntityOfType: (NSString *)entityType forField:(NSString *)fieldName;
- (NSString *)schemaFieldCreateForEntityOfType: (NSString *)entityType ofDataType:(NSString *)dataType withDisplayName:(NSString *)displayName;
- (NSString *)schemaFieldCreateForEntityOfType: (NSString *)entityType ofDataType:(NSString *)dataType withDisplayName:(NSString *)displayName
                                 andProperties:(id)properties;
- (BOOL)schemaFieldUpdateForEntityOfType: (NSString *)entityType forField:(NSString *)fieldName withProperties:(id)properties;
- (BOOL)schemaFieldDeleteForEntityOfType: (NSString *)entityType forField:(NSString *)fieldName;
- (void)setSessionUuid: (NSString *)uuid;

#pragma mark Upload and Download Files
- (NSNumber *)uploadThumbnailForEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path;
- (NSNumber *)uploadForEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path;
- (NSNumber *)uploadForEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path
                          forField:(NSString *)fieldName withDisplayName:(NSString *)displayName andTagList:(NSString *)tagList;

- (NSData *)downloadAttachmentWithId: (NSNumber *)attachmentId;

#pragma mark -
#pragma mark Internal Methods

- (NSString *)_getSessionToken;

- (NSDictionary *)_callRpcWithMethod: (NSString *)method andParams:(id)params;
- (NSDictionary *)_callRpcWithMethod: (NSString *)method andParams:(id)params includeScriptName:(BOOL)includeScriptName returnFirst:(BOOL)first;

- (id)_visitData: (id)data withVisitor:(id (^)(id))visitor;
- (id)_transformOutboundWithData: (id)data;
- (id)_transformInboundWithData: (id)data;
- (NSDictionary *)_buildPayloadWithMethod: (NSString *)method andParams:(NSDictionary *)params includeScriptName:(BOOL)includeScriptName;
- (NSString *)_encodePayload: (NSDictionary *)payload;
- (id)_decodeResponseWithHeaders: (NSDictionary *)headers andBody:(NSString *)body;
- (void)_responseErrors: (id)response;
- (void)_makeCallWithPath: (NSString *)path andBody:(NSString *)body andHeaders:(NSDictionary *)headers andHTTPMethod:(NSString *)method
           responseStatus:(NSInteger *)responseStatus responseHeaders:(NSDictionary **)responseHeaders responseBody:(NSString **)responseBody;
- (NSArray *)_parseRecords: (id)records;
- (NSString *)_buildThumbUrlForEntityOfType: (NSString *)entityType andId:(NSNumber *)entityId;
- (NSArray *)_listFromObj: (id)obj;
- (NSArray *)_listFromObj: (id)obj withKeyName: (NSString *)keyName andValueName: (NSString *)valueName;

@end
