/*
 * Copyright (c) 2013 Algolia
 * http://www.algolia.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "ASAPIClient.h"
#import "ASAPIClient+Network.h"
#import "ASRemoteIndex.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#include <Cocoa/Cocoa.h>
#endif

@implementation ASAPIClient

+(id) apiClientWithApplicationID:(NSString*)applicationID apiKey:(NSString*)apiKey hostnames:(NSArray*)hostnames
{
    return [[ASAPIClient alloc] initWithApplicationID:applicationID apiKey:apiKey hostnames:hostnames];
}

-(id) initWithApplicationID:(NSString*)papplicationID apiKey:(NSString*)papiKey hostnames:(NSArray*)phostnames
{
    self = [super init];
    if (self) {
        self.applicationID = papplicationID;
        self.apiKey = papiKey;
        if (phostnames == nil)
            @throw [NSException exceptionWithName:@"InvalidArgument" reason:@"List of hosts must be set" userInfo:nil];
        NSMutableArray *array = [NSMutableArray arrayWithArray:phostnames];
        srandom((unsigned int)time(NULL));
        NSUInteger count = [array count];
        for (NSUInteger i = 0; i < count; ++i) {
            // Select a random element between i and end of array to swap with.
            NSUInteger nElements = count - i;
            NSUInteger n = (random() % nElements) + i;
            [array exchangeObjectAtIndex:i withObjectAtIndex:n];
        }
        self.hostnames = array;
        if (self.applicationID == nil || [self.applicationID length] == 0)
            @throw [NSException exceptionWithName:@"InvalidArgument" reason:@"Application ID must be set" userInfo:nil];
        if (self.apiKey == nil || [self.apiKey length] == 0)
            @throw [NSException exceptionWithName:@"InvalidArgument" reason:@"APIKey must be set" userInfo:nil];
        if ([self.hostnames count] == 0)
            @throw [NSException exceptionWithName:@"InvalidArgument" reason:@"List of hosts must be set" userInfo:nil];
        NSMutableArray *httpClients = [[NSMutableArray alloc] init];
        for (NSString *host in self.hostnames) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", host]];
            AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
            [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
            [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
            [httpClient setParameterEncoding:AFJSONParameterEncoding];
            [httpClients addObject:httpClient];
        }
        clients = httpClients;
    }
    return self;
}

-(void) listIndexes:(void(^)(id JSON))success failure:(void(^)(NSString *errorMessage))failure
{
    [self performHTTPQuery:@"/1/indexes" method:@"GET" body:nil index:0 success:success failure:failure];
}

-(void) deleteIndex:(NSString*)indexName success:(void(^)(NSString *indexName, NSDictionary *JSON))success
            failure:(void(^)(NSString *indexName, NSString *errorMessage))failure
{
    NSString *path = [NSString stringWithFormat:@"/1/indexes/%@", [ASAPIClient urlEncode:indexName]];
    
    [self performHTTPQuery:path method:@"DELETE" body:nil index:0 success:^(id JSON) {
        if (success != nil)
            success(indexName, JSON);
    } failure:^(NSString *errorMessage) {
        if (failure != nil)
            failure(indexName, errorMessage);
    }];
}

-(void) listUserKeys:(void(^)(id JSON))success
                     failure:(void(^)(NSString *errorMessage))failure
{
    [self performHTTPQuery:@"/1/keys" method:@"GET" body:nil index:0 success:success failure:failure];
}

-(void) getUserKeyACL:(NSString*)key success:(void(^)(NSString *key, NSDictionary *JSON))success
                      failure:(void(^)(NSString *key, NSString *errorMessage))failure
{
    NSString *path = [NSString stringWithFormat:@"/1/keys/%@", key];
    [self performHTTPQuery:path method:@"GET" body:nil index:0 success:^(id JSON) {
        if (success != nil)
            success(key, JSON);
    } failure:^(NSString *errorMessage) {
        if (failure != nil)
            failure(key, errorMessage);
    }];
}

-(void) deleteUserKey:(NSString*)key success:(void(^)(NSString *key, NSDictionary *JSON))success
                       failure:(void(^)(NSString *key, NSString *errorMessage))failure
{
    NSString *path = [NSString stringWithFormat:@"/1/keys/%@", key];
    [self performHTTPQuery:path method:@"DELETE" body:nil index:0 success:^(id JSON) {
        if (success != nil)
            success(key, JSON);
    } failure:^(NSString *errorMessage) {
        if (failure != nil)
            failure(key, errorMessage);
    }];
}

-(void) addUserKey:(NSArray*)acls success:(void(^)(NSArray *acls, NSDictionary *JSON))success
           failure:(void(^)(NSArray *acls, NSString *errorMessage))failure
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:acls forKey:@"acl"];
    [self performHTTPQuery:@"/1/keys" method:@"POST" body:dict index:0 success:^(id JSON) {
        if (success != nil)
            success(acls, JSON);
    } failure:^(NSString *errorMessage) {
        if (failure != nil)
            failure(acls, errorMessage);
    }];
}

-(ASRemoteIndex*) getIndex:(NSString*)indexName
{
    return [ASRemoteIndex remoteIndexWithAPIClient:self indexName:indexName];
}

@synthesize applicationID;
@synthesize apiKey;
@synthesize hostnames;
@synthesize clients;
@end