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
 * @section toc Table of Contents
 * <ul>
 *   <li>@ref Introduction</li>
 *   <li>@ref Installation</li>
 *   <li>@ref Notes</li>
 *   <li>@ref details</li>
 *   <ul>
 *     <li>@ref connecting</li>
 *     <li>@ref finding</li>
 *     <li>@ref modifying</li>
 *     <li>@ref batch</li>
 *     <li>@ref schema</li>
 *     <li>@ref files</li>
 *     <li>@ref requests</li>
 *   </ul>
 *   <li>@ref TODOs</li>
 *   <li>@ref Dependencies</li>
 *   <li>@ref Links</li>
 * </ul>
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
 *  <li>Copy the dependencies into your project.\n\n
 *      All the dependencies are included as git submodules in the Dependencies directory.\n
 *      You can either download the dependencies yourself or (if you cloned the project via\n
 *      git rather than downloading the tarball) run 'git submodule init' followed by\n
 *      'git submodule update' to download the projects at the revision as of the writing of\n
 *      this library.\n\n
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
 * @section Notes
 *  \li All NSDate objects are assumed to be in UTC (This is the default NSDate behavior).
 *
 * @section details API Details
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
 *   ShotgunRequest *request = 
 *     [shotgun findEntityOfType:@"Version"
 *                   withFilters:@"[[\"code\", \"starts_with\", \"100\"]]"
 *                     andFields:@"[\"code\", \"image\"]"];
 *   [request startSynchronous];
 *   NSArray *results = [request response];
 *   \endcode
 *
 *   @subsection modifying Creating, modifying, deleting, and reviving entities
 *   \code
 *   ShotgunRequest *request = [shotgun createEntityOfType:@"Shot"
 *                                           withData:@"{\"code\": \"s10\", \"description\": \"Shot 10\"}"];
 *   [request startSynchronous];
 *   ShotgunEntity *shot = [request response];
 *   \endcode
 *   \code
 *   ShotgunRequest *request = [shotgun updateEntityOfType:@"Shot"
 *                                             withId:[NSNumber numberWithInt:23]
 *                                           withData:@"{\"description\": \"Shot 20 - More Info\"}"];
 *   [request startSynchronous];
 *   ShotgunEntity *shot = [request response];
 *   \endcode
 *   \code
 *   ShotgunRequest *request = [shotgun deleteEntityOfType:@"Shot" withId:[NSNumber numberWithInt:23]];
 *   [request startSynchronous];
 *   BOOL success = [[request response] boolValue];
 *   \endcode
 *   \code
 *   ShotgunRequest *request = [shotgun reviveEntityOfType:@"Shot" withId:[NSNumber numberWithInt:23]];
 *   [request startSynchronous];
 *   BOOL success = [[request response] boolValue];
 *   \endcode
 *
 *   @subsection batch Batch operations
 *   \code
 *   ShotgunRequest *request = [shotgun batch:@"[" \
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
 *   [request startSynchronous];
 *   NSArray *results = [request response];
 *   \endcode
 *
 *   @subsection schema Meta-Schema queries
 *   \code
 *   ShotgunRequest *request = [shotgun schemaEntityRead];
 *   [request startSynchronous];
 *   NSDictionary *schemaInfo = [request response];
 *   \endcode
 *   \code
 *   ShotgunRequest *request = [shotgun schemaRead];
 *   [request startSynchronous];
 *   NSDictionary *schema = [request response];
 *   \endcode
 *   \code
 *   ShotgunRequest *request = [shotgun schemaFieldReadForEntityOfType:@"Shot" forField:@"sg_status_list"];
 *   [request startSynchronous];
 *   NSDictionary *entitySchema = [request response];
 *   \endcode
 *
 *   @subsection files Uploading and downloading files
 *   \code
 *   NSNumber *attachmentId = [shotgun uploadThumbnailForEntityOfType:@"Shot"
 *                                          withId:[NSNumber numberWithInt:23]
 *                                        fromPath:@"/path/to/the/file.jpg"];
 *   \endcode
 *   \code
 *   NSData *imageData = downloadAttachmentWithId:[NSNumber numberWithInt:201];
 *   \endcode
 *
 *   @subsection requests Using ShotgunRequest Objects
 *   ShotgunRequests can be run either synchronously or asynchronously.
 *
 *   To run a request syncronously simply call startSyncronously:
 *   \code
 *   [request startSyncronous];
 *   \endcode
 *   The request will block the current thread until it is finished and its response is ready.
 *
 *   To run a request asynchronously call startAsynchronous:
 *   \code
 *   [request startAsynchronous];
 *   \endcode
 *   Control will return to the current thread right away.  To process the response to the
 *   request, register callback blocks with request before starting it:
 *   \code
 *   [request setCompletionBlock:^{
 *      id response = [request response];
 *      // Do Stuff with the response
 *   }];
 *   \endcode
 *
 *   The currently supported callbacks are:
 *   \li startedBlock - Called when the request is started.
 *   \li completionBlock - Called when the request has finished.
 *   \li failedBlock - Called when the request failed.
 *
 *   The postProcessBlock is used internally to the API and should not be overridden.
 *
 * @section TODOs
 *   @li Switch from Exceptions to NSErrors
 *   @li Add support for responding to events via delegate SELs
 *   @li Add support for asychronous image field resolution
 *   @li Better API around paging
 *   @li Finish documentation
 *   @li Round out unit tets.  Use <a href="http://www.mulle-kybernetik.com/software/OCMock/">OCMock</a>.
 *   @li Switch to a decent logging system
 *   @li \ref todo "Other inline TODOs"
 *
 * @section Dependencies
 *  \li ASIHTTPRequest: http://allseeing-i.com/ASIHTTPRequest/
 *  \li SBJson: http://stig.github.com/json-framework/
 *  \li GHUnit (only needed to run the unit tests): https://github.com/gabriel/gh-unit
 *
 * @section Links
 * \li Python API: https://github.com/shotgunsoftware/python-api
 * \li Mailing List: https://groups.google.com/group/shotgun-objc-api
 * \li Issues: https://github.com/robblau/objc-api/issues
 *
 * Rob Blau <rblau@laika.com>
 *
 */

#pragma mark - Interface

#import <Foundation/Foundation.h>

#import "ShotgunEntity.h"
#import "ShotgunRequest.h"

/** Represents a connection to a shotgun server. */
@interface Shotgun : NSObject;

#pragma mark - Initialize

/*! Connect to shotgun.
 *
 * See initWithUrl
 */
+ (id)shotgunWithUrl:(NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key;

/*! Connect to shotgun.
 *
 * @param url The url of the server to connect to.
 * @param scriptName The name of the script to connect as.
 * @param key The key for the script.
 *
 * @return A Shotgun object.
 * @exception NSException Raises if the connection fails.
 */
- (id)initWithUrl:(NSString *)url scriptName:(NSString *)scriptName andKey:(NSString *)key;

#pragma mark Query Information

/*! Return information about the shotgun server.
 *
 * @return A ShotgunRequest whose response is an NSDictionary with information about the server.
 */
- (ShotgunRequest *)info;

- (ShotgunRequest *)findEntityOfType:(NSString *)entityType withFilters:(id)filters;
- (ShotgunRequest *)findEntityOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields;
- (ShotgunRequest *)findEntityOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                          andOrder:(id)order andFilterOperator:(NSString *)filterOperator retiredOnly:(BOOL)retiredOnly;
- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters;
- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields;
- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
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
 * @return A ShotgunRequest whose response is an NSArray of ShotgunEntity objects that match the filters.
 */
- (ShotgunRequest *)findEntitiesOfType:(NSString *)entityType withFilters:(id)filters andFields:(id)fields 
                       andOrder:(id)order andFilterOperator:(NSString *)filterOperator andLimit:(NSUInteger)limit
                        andPage:(NSUInteger)page retiredOnly:(BOOL)retiredOnly;

#pragma mark Modify Information

- (ShotgunRequest *)createEntityOfType:(NSString *)entityType withData:(id)data;

/*! Create a new entity
 *
 * @param entityType An NSString specifying the type of entity to return.
 * @param data An NSDictionary specifying values for fields on the new entity (or an NSString that is well formed JSON describing the same value).
 * @param returnFields An NSArray of NSStrings specifying what fields to return (or an NSString that is well formed JSON describing the same value).
 *
 * @return A ShotgunRequest whose response is a ShotgunEntity representing the created entity populated with the specified @p returnFields.
 */
- (ShotgunRequest *)createEntityOfType:(NSString *)entityType withData:(id)data returnFields:(id)returnFields;

/*! Update an existing entity
 *
 * @param entityType An NSString specifying the type of entity to return.
 * @param entityId An NSNumber with the id of the entity to update.
 * @param data An NSDictionary specifying values for fields on the new entity (or an NSString that is well formed JSON describing the same value).
 * @param returnFields An NSArray of NSStrings specifying what fields to return (or an NSString that is well formed JSON describing the same value).
 *
 * @return A ShotgunRequest whose response is a ShotgunEntity representing the created entity populated with the specified @p returnFields.
 */
- (ShotgunRequest *)updateEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId withData:(id)data;

/*! Retire an entity from the database
 *
 * @param entityType An NSString specifying the type of entity to retire.
 * @param entityId An NSNumber with the id of the entity to retire.
 *
 * @return A ShotgunRequest whose response is a NSNumber whose boolValue is TRUE if the entity was retired.  FALSE otherwise.
 */
- (ShotgunRequest *)deleteEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId;

/*! Revive an entity from the database
 *
 * @param entityType An NSString specifying the type of entity to revive.
 * @param entityId An NSNumber with the id of the entity to revive.
 *
 * @return A ShotgunRequest whose response is a NSNumber whose boolValue is TRUE if the entity was revived.  FALSE otherwise.
 */
- (ShotgunRequest *)reviveEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId;

/*! Run a series of operations on the server in a transaction
 *
 * @param requests An NSArray of NSDictionary specifying the operation to run (or an NSString that is well formed JSON describing the same value).
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods#batch">official batch docs</a> for details on the format of @p requests.
 *
 * @return A ShotgunRequest whose response is an NSArray where each element is the return value of its corresponding request.
 */
- (ShotgunRequest *)batch:(id)requests;

#pragma mark Meta Schema

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (ShotgunRequest *)schemaEntityRead;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (ShotgunRequest *)schemaRead;
- (ShotgunRequest *)schemaFieldReadForEntityOfType:(NSString *)entityType;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (ShotgunRequest *)schemaFieldReadForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName;
- (ShotgunRequest *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType withDisplayName:(NSString *)displayName;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (ShotgunRequest *)schemaFieldCreateForEntityOfType:(NSString *)entityType ofDataType:(NSString *)dataType withDisplayName:(NSString *)displayName
                                 andProperties:(id)properties;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (ShotgunRequest *)schemaFieldUpdateForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName withProperties:(id)properties;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (ShotgunRequest *)schemaFieldDeleteForEntityOfType:(NSString *)entityType forField:(NSString *)fieldName;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (void)setSessionUuid:(NSString *)uuid;

#pragma mark Upload and Download Files

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (NSNumber *)uploadThumbnailForEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path;
- (NSNumber *)uploadForEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (NSNumber *)uploadForEntityOfType:(NSString *)entityType withId:(NSNumber *)entityId fromPath:(NSString *)path
                          forField:(NSString *)fieldName withDisplayName:(NSString *)displayName andTagList:(NSString *)tagList;

/*!
 * @see The <a href="https://github.com/shotgunsoftware/python-api/wiki/Reference%3A-Methods">official docs</a>
 */
- (NSData *)downloadAttachmentWithId:(NSNumber *)attachmentId;

@end
