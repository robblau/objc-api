//
//  Shotgun.h
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

#pragma mark - Main Page Documentation

/*!
 *
 * @mainpage %Shotgun API
 *
 * @section Introduction
 * This is an objective c port of the python shotgun api.
 *
 * For complete documentation of how the %Shotgun API works along with
 * tutorials, examples, and other details see:\n
 * https://github.com/shotgunsoftware/python-api/wiki
 *
 * @section Installation
 *  <ul>
 *  <li>Start by downloading the code from https://github.com/robblau/objc-api</li>
 *  <li>Copy the files in Classes directory into your project.</li>
 *  <li>Copy the dependencies into your project (these are included in the Dependencies directory).
 *    <ul>
 *      <li><b>json-framework</b> - Copy the files in Classes into your project.</li>
 *      <li><b>asi-http-request</b> (<i>See the <a href="http://allseeing-i.com/ASIHTTPRequest/Setup-instructions">official docs</a> for more in depth instructions).</i>
 *        <ul>
 *          <li>Copy the files in Classes into your project (just the files, the directories are not needed)</li>
 *          <li>Copy the files in External/Reachability into your project.</li>
 *          <li>Link against CFNetwork, SystemConfiguration, MobileCoreServices, CoreGraphics and zlib</li>
 *        </ul>
 *      </li>
 *    </ul>
 *  </li>
 *  </ul>
 *  See the example project under Examples to see what the resulting setup should look like.
 *
 * @section API Details
 *   @subsection connecting Connecting to Shotgun
 *   \code
 *   NSString *url = @"http://mysite.shotgunsoftware.com";
 *   NSString *script = @"example_script";
 *   NSString *key = @"abcdefghijklmnopqrstuvwxyz";
 *   Shotgun *shotgun = [[[Shotgun alloc] initWithUrl:url scriptName:script andKey:key] autorelease];
 *   \endcode
 *
 *   @subsection finding Finding entities
 *   \code
 *   NSArray *results =
 *     [shotgun findEntityOfType:@"Version"
 *                   withFilters:@"[[\"code\", \"starts_with\", \"100\"]]"
 *                     andFields:@"[\"code\", \"image\"]"];
 *   \endcode
 *
 *   @subsection modifying Creating, modifying, deleting, and reviving entities
 *   \code
 *   NSDictionary *shot = [shotgun createEntityOfType:@"Shot"
 *                                           withData:@"{\"code\": \"s10\", \"description\": \"Shot 10\"}"];
 *   \endcode
 *   \code
 *   NSDictionary *shot = [shotgun updateEntityOfType:@"Shot"
 *                                             withId:[NSNumber numberWithInt:23]
 *                                           withData:@"{\"description\": \"Shot 20 - More Info\"}"];
 *   \endcode
 *   \code
 *   BOOL success = [shotgun deleteEntityOfType:@"Shot" withId:[NSNumber numberWithInt:23]];
 *   \endcode
 *   \code
 *   BOOL success = [shotgun reviveEntityOfType:@"Shot" withId:[NSNumber numberWithInt:23]];
 *   \endcode
 *
 *   @subsection batch Batch operations
 *   \code
 *   NSArray *results = [shotgun batch:@"["   \
 *       "{                                 " \
 *       " \"request_type\": \"create\",    " \
 *       " \"entity_type\":  \"Shot\",      " \
 *       " \"data\": {                      " \
 *       "     \"code\": \"s10\",           " \
 *       "     \"description\": \"Shot 10\" " \
 *       "   }                              " \
 *       "},                                " \
 *       "{\"request_type\": \"delete\", \"entity_type\": \"Shot\", \"entity_id\": 23}" \
 *     ]"];
 *   \endcode
 *
 *   @subsection schema Meta-Schema queries
 *   \code
 *   NSDictionary *schemaInfo = [shotgun schemaEntityRead];
 *   \endcode
 *   \code
 *   NSDictionary *schema = [shotgun schemaRead];
 *   \endcode
 *   \code
 *   NSDictionary *entitySchema = [shotgun schemaFieldReadForEntityOfType:@"Shot" forField:@"sg_status_list"];
 *   \endcode
 *
 *   @subsection files Uploading and downloading files
 *   \code
 *     NSNumber *attachmentId = [shotgun uploadThumbnailForEntityOfType:@"Shot"
 *                                            withId:[NSNumber numberWithInt:23]
 *                                          fromPath:@"/path/to/the/file.jpg"];
 *   \endcode
 *   \code
 *   NSData *imageData = downloadAttachmentWithId:[NSNumber numberWithInt:201];
 *   \endcode
 *
 * @section TODOs
 *   @li Asynchronous calls
 *   @li Switch from Exceptions to NSErrors
 *   @li Add support for responding to events via blocks and delegate SELs
 *   @li Add support for asychronous image field resolution
 *   @li Better API around paging
 *   @li Finish documentation
 *   @li Round out unit tets.  Use <a href="http://www.mulle-kybernetik.com/software/OCMock/">OCMock</a>.
 *   @li \ref todo "Other inline TODOs"
 *
 * @section Dependencies
 *  \li ASIHTTPRequest: http://allseeing-i.com/ASIHTTPRequest/
 *  \li SBJson: http://stig.github.com/json-framework/
 *
 * @section Links
 * \li Python API: https://github.com/shotgunsoftware/python-api
 * \li Issues: https://github.com/robblau/objc-api/issues
 *
 * Rob Blau <rblau@laika.com>
 *
 */

#pragma mark - Interface

#import <Foundation/Foundation.h>
#import "ShotgunEntity.h"

@class Config;
@class ShotgunRequest;
@class ServerCapabilities;
@class ClientCapabilities;

/** Represents a connection to a shotgun server. */
@interface Shotgun : NSObject {
@private
    Config *myConfig;
    ServerCapabilities *myServerCaps;
    ClientCapabilities *myClientCaps;
}

#pragma mark -
#pragma mark Public Methods

- (id)initWithUrl: (NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key;

/*! Connect to shotgun.
 *
 * @param url The url of the server to connect to.
 * @param scriptName The name of the script to connect as.
 * @param key The key for the script.
 * @param convertDatetimesToUTC If YES then NSDates are assumed to be in UTC.
 *    Otherwise the local timezone is assumed.  The default is YES.
 *
 * @return A Shotgun object.
 * @exception NSException Raises if the connection fails.
 */
- (id)initWithUrl: (NSString *)url scriptName:(NSString *)scriptName
           andKey:(NSString *)key andConvertDatetimesToUTC:(BOOL)convertDatetimesToUTC;

#pragma mark Query Information
/*! Return information about the shotgun server.
 *
 * @return An NSDictionary with information about the server.
 */
- (NSDictionary *)info;

- (ShotgunEntity *)findEntityOfType: (NSString *)entityType withFilters:(id)filters;
- (ShotgunEntity *)findEntityOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields;
- (ShotgunEntity *)findEntityOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                          andOrder:(id)order andFilterOperator:(NSString *)filterOperator retiredOnly:(BOOL)retiredOnly;
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters;
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields;
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator;

/*! Return information about shotgun entities from the server.
 *
 * @param entityType An NSString specifying the type of entity to return.
 * @param filters An NSArray or NSDictionary  corresponding to the valid filter values
 *      from the python API (or an NSString that is well formed JSON describing the same value).
 * @param fields An NSArray of NSString that specifies what fields to return (or an NSString that is well formed JSON describing the same value).
 * @param order An NSArray of NSDictionary that specifies what fields to sort by (or an NSString that is well formed JSON describing the same value).
 * @param filterOperator A string that controls whether to join @p filters as an 'and' (when @p filterOperator is @"all")
 *      or as an 'or' (when @p filterOperator is anything else).
 * @param limit An NSUInteger.  Specifies the max number of entities to return.
 * @param page An NSUInteger.  When specified will return page @p page of the results.
 * @param retiredOnly A BOOL.  Return retired entities if YES.  Un-retired entities otherwise.
 *
 * @return An NSArray of ShotgunEntity objects that match the filters.
 */
- (NSArray *)findEntitiesOfType: (NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator andLimit:(NSUInteger)limit
                        andPage:(NSUInteger)page retiredOnly:(BOOL)retiredOnly;

#pragma mark Modify Information
- (ShotgunEntity *)createEntityOfType: (NSString *)entityType withData:(id)data;

/*! Create a new entity
 *
 * @param entityType An NSString specifying the type of entity to return.
 * @param data An NSDictionary specifying values for fields on the new entity (or an NSString that is well formed JSON describing the same value).
 * @param returnFields An NSArray of NSStrings specifying what fields to return (or an NSString that is well formed JSON describing the same value).
 *
 * @return A ShotgunEntity representing the created entity populated with the specified @p returnFields.
 */
- (ShotgunEntity *)createEntityOfType: (NSString *)entityType withData:(id)data returnFields:(id)returnFields;

/*! Update an existing entity
 *
 * @param entityType An NSString specifying the type of entity to return.
 * @param entityId An NSNumber with the id of the entity to update.
 * @param data An NSDictionary specifying values for fields on the new entity (or an NSString that is well formed JSON describing the same value).
 * @param returnFields An NSArray of NSStrings specifying what fields to return (or an NSString that is well formed JSON describing the same value).
 *
 * @return A ShotgunEntity representing the created entity populated with the specified @p returnFields.
 */
- (ShotgunEntity *)updateEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId withData:(id)data;

/*! Retire an entity from the database
 *
 * @param entityType An NSString specifying the type of entity to retire.
 * @param entityId An NSNumber with the id of the entity to retire.
 *
 * @return TRUE if the entity was retired.  FALSE otherwise.
 */
- (BOOL)deleteEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId;

/*! Revive an entity from the database
 *
 * @param entityType An NSString specifying the type of entity to revive.
 * @param entityId An NSNumber with the id of the entity to revive.
 *
 * @return TRUE if the entity was revived.  FALSE otherwise.
 */
- (BOOL)reviveEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId;

/*! Run a series of operations on the server in a transaction
 *
 * @param requests An NSArray of NSDictionary specifying the operation to run (or an NSString that is well formed JSON describing the same value).
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods#batch">official batch docs</a> for details on the format of @p requests.
 *
 * @return An NSArray where each element is the return value of its corresponding request.
 */
- (NSArray *)batch: (id)requests;

#pragma mark Meta Schema
/*! */
- (NSDictionary *)schemaEntityRead;
/*! */
- (NSDictionary *)schemaRead;
- (NSDictionary *)schemaFieldReadForEntityOfType: (NSString *)entityType;
/*! */
- (NSDictionary *)schemaFieldReadForEntityOfType: (NSString *)entityType forField:(NSString *)fieldName;
- (NSString *)schemaFieldCreateForEntityOfType: (NSString *)entityType ofDataType:(NSString *)dataType withDisplayName:(NSString *)displayName;
/*! */
- (NSString *)schemaFieldCreateForEntityOfType: (NSString *)entityType ofDataType:(NSString *)dataType withDisplayName:(NSString *)displayName
                                 andProperties:(id)properties;
/*! */
- (BOOL)schemaFieldUpdateForEntityOfType: (NSString *)entityType forField:(NSString *)fieldName withProperties:(id)properties;
/*! */
- (BOOL)schemaFieldDeleteForEntityOfType: (NSString *)entityType forField:(NSString *)fieldName;
/*! */
- (void)setSessionUuid: (NSString *)uuid;

#pragma mark Upload and Download Files
/*! */
- (NSNumber *)uploadThumbnailForEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path;
- (NSNumber *)uploadForEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path;
/*! */
- (NSNumber *)uploadForEntityOfType: (NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path
                          forField:(NSString *)fieldName withDisplayName:(NSString *)displayName andTagList:(NSString *)tagList;

/*! */
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
