//
//  ShotgunRequest.h
//  UnitTests
//
//  Created by Rob Blau on 6/15/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ASIHTTPRequestDelegate.h"

@class ShotgunConfig;

/// @typedef A block taking no parameters and returning no value
typedef void (^ShotgunRequestBlock)(void);
/// @typedef A block taking an NSDictionary and an NSString as parameters and returning an id
typedef id (^ShotgunPostProcessBlock)(NSDictionary *, NSString *);

#pragma mark ShotgunRequest

/** Represents a simple request being made to a %Shotgun instance. */
@interface ShotgunRequest : NSOperation <ASIHTTPRequestDelegate>;

/*! Initialize a request
 *
 * See initWithConfig:path:body:headers:andHTTPMethod:
 */
+ (id)shotgunRequestWithConfig:(ShotgunConfig *)config path:(NSString *)path body:(NSString *)body headers:(NSDictionary *)headers andHTTPMethod:(NSString *)method;

/*! Initialize the request
 *
 * @param config A ShotgunConfig with the information on what host to connect to and how to authenticate
 * @param path A string with the path portion of the url to call on the %Shotgun server
 * @param body A string with the body of the request to send to the %Shotgun server
 * @param headers An NSDictionary with the headers for the request to send to the %Shotgun server
 * @param method A string with the HTTP method to use to talk to the %Shotgun server (ie POST)
 *
 * @return A ShotgunRequest object
 */
- (id)initWithConfig:(ShotgunConfig *)config path:(NSString *)path body:(NSString *)body headers:(NSDictionary *)headers andHTTPMethod:(NSString *)method;

/** Start the connection blocking the current thread until the request is finished */
- (void)startSynchronous;

/** Start the connection */
- (void)startAsynchronous;

- (void)dealloc;

@property (retain, readonly, nonatomic) id response; ///< The return value of the request
@property (retain, readonly, nonatomic) NSError *error; ///< The value of an error if it occurred.

@property (retain, readwrite, nonatomic) NSOperationQueue *queue; ///< The operation queue to run in.  Defaults to the main queue.
@property (copy, readwrite, nonatomic) ShotgunRequestBlock startedBlock; ///< The block called when the request is started
@property (copy, readwrite, nonatomic) ShotgunRequestBlock completionBlock; ///< The block called when the request completes
@property (copy, readwrite, nonatomic) ShotgunRequestBlock failedBlock; ///< The block called when the request errors

@property (assign, readonly, nonatomic) BOOL isFinished;
@property (assign, readonly, nonatomic) BOOL isExecuting;

@end