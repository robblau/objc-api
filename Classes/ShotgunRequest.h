//
//  ShotgunRequest.h
//  UnitTests
//
//  Created by Rob Blau on 6/15/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ASIHTTPRequest.h"

@class ShotgunEntity;
@class ShotgunConfig;

/// @typedef A block taking no parameters and returning no value
typedef void (^ShotgunRequestBlock)(void);
/// @typedef A block taking an NSDictionary and an NSString as parameters and returning an id
typedef id (^ShotgunPostProcessBlock)(NSDictionary *, NSString *);

#pragma mark ShotgunRequest

/** Represents a simple request being made to a %Shotgun instance. */
@interface ShotgunRequest : NSObject <ASIHTTPRequestDelegate> {
    NSUInteger timeout;
    NSUInteger maxAttempts;
    NSString *responseBody;
    NSUInteger _currentAttempt;
    ASIHTTPRequest *_request;
    ShotgunRequestBlock startedBlock;
    ShotgunRequestBlock completionBlock;
    ShotgunRequestBlock failureBlock;
    ShotgunPostProcessBlock postProcessBlock;
    id processedResults;
}

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

/** The return value of the request */
- (id)response;

@property (readwrite, copy) ShotgunRequestBlock startedBlock; ///< The block called when the request is started
@property (readwrite, copy) ShotgunRequestBlock completionBlock; ///< The block called when the request completes
@property (readwrite, copy) ShotgunRequestBlock failedBlock; ///< The block called when the request errors
@property (readwrite, copy) ShotgunPostProcessBlock postProcessBlock; ///< Internally used to process the raw results from the server

@end