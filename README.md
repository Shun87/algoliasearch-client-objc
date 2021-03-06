Algolia Search API Client for iOS and OS X
==================

This Objective-C client let you easily use the Algolia Search API from your application.
The service is currently in Beta, you can request an invite on our [website](http://www.algolia.com/pricing/).

Table of Content
-------------
**Get started**

1. [Setup](#setup) 
1. [Quick Start](#quick-start)

**Commands reference**

1. [Search](#search)
1. [Add a new object](#add-a-new-object-in-the-index)
1. [Update an object](#update-an-existing-object-in-the-index)
1. [Get an object](#get-an-object)
1. [Delete an object](#delete-an-object)
1. [Index settings](#index-settings)
1. [List indexes](#list-indexes)
1. [Delete an index](#delete-an-index)
1. [Wait indexing](#wait-indexing)
1. [Batch writes](#batch-writes)
1. [Security / User API Keys](#security--user-api-keys)

Setup
-------------
To setup your project, follow these steps:

 1. Use cocoapods or Add source to your project by adding `pod 'AlgoliaSearch-Client', '~> 1.0'`in your Podfile or drop the source folder on your project (If you are not using a Podfile, you will also need to add [AFNetworking library](https://github.com/AFNetworking/AFNetworking) in your project).
 2. Add the `#import "ASAPIClient.h"` call to your project
 3. Initialize the client with your ApplicationID, API-Key and list of hostnames (you can find all of them on your Algolia account)

```objc
  ASAPIClient *apiClient = 
    [ASAPIClient apiClientWithApplicationID:@"YourApplicationID" apiKey:@"YourAPIKey" 
                hostnames:[NSArray arrayWithObjects:@"YourHostname-1.algolia.io", 
                                                    @"YourHostname-2.algolia.io", 
                                                    @"YourHostname-3.algolia.io", nil]];
```

Quick Start
-------------
This quick start is a 30 seconds tutorial where you can discover how to index and search objects.

Without any prior-configuration, you can index the 1000 world's biggest cities in the ```cities``` index with the following code:
```objc
// Load JSON file
NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"1000-cities" ofType:@"json"];
NSData* jsonData = [NSData dataWithContentsOfFile:jsonPath];
NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
// Load all objects of json file in an index named "cities"
ASRemoteIndex *index = [apiClient getIndex:@"cities"];
[apiClient listIndexes:^(id JSON) {
  NSLog(@"Indexes: %@", JSON);
} failure:nil];
```
The [1000-cities.json](https://github.com/algolia/algoliasearch-client-objc/blob/master/1000-cities.json) file contains city names extracted from [Geonames](http://www.geonames.org).

You can then start to search for a city name (even with typos):
```objc
[index search:[ASQuery queryWithFullTextQuery:@"san fran"] 
  success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *result) {
    NSLog(@"Result:%@", result);
} failure:nil];
[index search:[ASQuery queryWithFullTextQuery:@"loz anqel"] 
  success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *result) {
    NSLog(@"Result:%@", result);
} failure:nil];
```

Settings can be customized to tune the index behavior. For example you can add a custom sort by population to the already good out-of-the-box relevance to raise bigger cities above smaller ones. To update the settings, use the following code:
```objc
NSArray *customRanking = [NSArray arrayWithObjects:@"desc(population)", @"asc(name)", nil];
NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:customRanking, @"customRanking", nil];
[index setSettings:settings success:nil
  failure:^(ASRemoteIndex *index, NSDictionary *settings, NSString *errorMessage) {
    NSLog(@"Error when applying settings: %@", errorMessage);
}]
```

And then search for all cities that start with an "s":
```objc
[index search:[ASQuery queryWithFullTextQuery:@"s"] 
  success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *result) {
    NSLog(@"Result:%@", result);
} failure:nil];
```

Search
-------------
To perform a search, you just need to initialize the index and perform a call to the search function.<br/>
You can use the following optional arguments on ASQuery class:

 * **fullTextQuery**: the full text query.
 * **attributesToRetrieve**: specify the list of attribute names to retrieve.<br/>By default all attributes are retrieved.
 * **attributesToHighlight**: specify the list of attribute names to highlight.<br/>By default indexed attributes are highlighted. Numerical attributes cannot be highlighted. A **matchLevel** is returned for each highlighted attribute and can contain: "full" if all the query terms were found in the attribute, "partial" if only some of the query terms were found, or "none" if none of the query terms were found.
 * **attributesToSnippet**: specify the list of attributes to snippet alongside the number of words to return (syntax is 'attributeName:nbWords').<br/>By default no snippet is computed.
 * **minWordSizeForApprox1**: the minimum number of characters in a query word to accept one typo in this word.<br/>Defaults to 3.
 * **minWordSizeForApprox2**: the minimum number of characters in a query word to accept two typos in this word.<br/>Defaults to 7.
 * **getRankingInfo**: if set to YES, the result hits will contain ranking information in _rankingInfo attribute.
 * **page**: *(pagination parameter)* page to retrieve (zero base).<br/>Defaults to 0.
 * **hitsPerPage**: *(pagination parameter)* number of hits per page.<br/>Defaults to 10.
 * **searchAroundLatitude:longitude:maxDist**: search for entries around a given latitude/longitude.<br/>You specify the maximum distance in meters with the **radius** parameter (in meters).<br/>At indexing, you should specify geoloc of an object with the _geoloc attribute (in the form `{"_geoloc":{"lat":48.853409, "lng":2.348800}}`)
 * **searchInsideBoundingBoxWithLatitudeP1:longitudeP1:latitudeP2:longitudeP2:**: search for entries inside a given area defined by the two extreme points of a rectangle.<br/>At indexing, you should specify geoloc of an object with the _geoloc attribute (in the form `{"_geoloc":{"lat":48.853409, "lng":2.348800}}`)
 * **queryType**: select how the query words are interpreted:
  * **prefixAll**: all query words are interpreted as prefixes (default behavior).
  * **prefixLast**: only the last word is interpreted as a prefix. This option is recommended if you have a lot of content to speedup the processing.
  * **prefixNone**: no query word is interpreted as a prefix. This option is not recommended.
 * **tags**: filter the query by a set of tags. You can AND tags by separating them by commas. To OR tags, you must add parentheses. For example, `tag1,(tag2,tag3)` means *tag1 AND (tag2 OR tag3)*.<br/>At indexing, tags should be added in the _tags attribute of objects (for example `{"_tags":["tag1","tag2"]}` )

```objc
ASRemoteIndex *index = [apiClient getIndex:@"MyIndexName"];
[index search:[ASQuery queryWithFullTextQuery:@"s"] 
  success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *result) {
    NSLog(@"Result:%@", result);
} failure:nil];

ASQuery *query = [ASQuery queryWithFullTextQuery:@"s"];
query.attributesToRetrieve = [NSArray arrayWithObjects:@"population", @"name", nil];
query.hitsPerPage = 50;
[index search:query 
  success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *result) {
    NSLog(@"Result:%@", result);
} failure:nil];
```

The server response will look like:

```javascript
{
    "hits":[
            { "name": "Betty Jane Mccamey",
              "company": "Vita Foods Inc.",
              "email": "betty@mccamey.com",
              "objectID": "6891Y2usk0",
              "_highlightResult": {"name": {"value": "Betty <em>Jan</em>e Mccamey", "matchLevel": "full"}, 
                                   "company": {"value": "Vita Foods Inc.", "matchLevel": "none"},
                                   "email": {"value": "betty@mccamey.com", "matchLevel": "none"} }
            },
            { "name": "Gayla Geimer Dan", 
              "company": "Ortman Mccain Co", 
              "email": "gayla@geimer.com", 
              "objectID": "ap78784310" 
              "_highlightResult": {"name": {"value": "Gayla Geimer <em>Dan</em>", "matchLevel": "full" },
                                   "company": {"value": "Ortman Mccain Co", "matchLevel": "none" },
                                   "email": {"highlighted": "gayla@geimer.com", "matchLevel": "none" } }
            }],
    "page":0,
    "nbHits":2,
    "nbPages":1,
    "hitsPerPage:":20,
    "processingTimeMS":1,
    "query":"jan"
}
```

Add a new object in the Index
-------------

Each entry in an index has a unique identifier called `objectID`. You have two ways to add en entry in the index:

 1. Using automatic `objectID` assignement, you will be able to retrieve it in the answer.
 2. Passing your own `objectID`

You don't need to explicitely create an index, it will be automatically created the first time you add an object.
Objects are schema less, you don't need any configuration to start indexing. The settings section provide details about advanced settings.

Example with automatic `objectID` assignement:

```objc
NSDictionary *newObject = [NSDictionary dictionaryWithObjectsAndKeys:@"San Francisco", @"name",
                                    [NSNumber numberWithInt:805235], @"population", nil];
[index addObject:newObject 
  success:^(ASRemoteIndex *index, NSDictionary *object, NSDictionary *result) {
    NSLog(@"Object ID:%@", [result valueForKey:@"objectID"]);
} failure:nil];
```

Example with manual `objectID` assignement:

```objc
NSDictionary *newObject = [NSDictionary dictionaryWithObjectsAndKeys:@"San Francisco", @"name",
                                    [NSNumber numberWithInt:805235], @"population", nil];
[index addObject:newObject withObjectID:@"myID" 
  success:^(ASRemoteIndex *index, NSDictionary *object, NSString *objectID, NSDictionary *result) {
    NSLog(@"Object ID:%@", [result valueForKey:@"objectID"]);
} failure:nil];
```

Update an existing object in the Index
-------------

You have two options to update an existing object:

 1. Replace all its attributes.
 2. Replace only some attributes.

Example to replace all the content of an existing object:

```objc
NSDictionary *newObject = [NSDictionary dictionaryWithObjectsAndKeys:@"Los Angeles", @"name",
                                    [NSNumber numberWithInt:3792621], @"population", nil];
[index saveObject:newObject objectID:@"myID" success:nil failure:nil];
```

Example to update only the population attribute of an existing object:

```objc
NSDictionary *partialObject = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3792621], @"population", nil];
[index partialUpdateObject:partialObject objectID:@"myID" success:nil failure:nil];
```

Get an object
-------------

You can easily retrieve an object using its `objectID` and optionnaly a list of attributes you want to retrieve (using comma as separator):

```objc
// Retrieves all attributes
[index getObject:@"myID" 
  success:^(ASRemoteIndex *index, NSString *objectID, NSDictionary *result) {
    NSLog(@"Object: %@", result);
} failure:nil];
// Retrieves only the name attribute
[index getObject:@"myID" attributesToRetrieve:[NSArray arrayWithObject:@"name"] 
  success:^(ASRemoteIndex *index, NSString *objectID, NSArray *attributesToRetrieve, NSDictionary *result) {
    NSLog(@"Object: %@", result);
} failure:nil];
```

Delete an object
-------------

You can delete an object using its `objectID`:

```objc
[index deleteObject:@"myID" success:nil failure:nil];
```

Index Settings
-------------

You can retrieve all settings using the `getSettings` function. The result will contains the following attributes:

 * **minWordSizeForApprox1**: (integer) the minimum number of characters to accept one typo (default = 3).
 * **minWordSizeForApprox2**: (integer) the minimum number of characters to accept two typos (default = 7).
 * **hitsPerPage**: (integer) the number of hits per page (default = 10).
 * **attributesToRetrieve**: (array of strings) default list of attributes to retrieve in objects.
 * **attributesToHighlight**: (array of strings) default list of attributes to highlight.
 * **attributesToSnippet**: (array of strings) default list of attributes to snippet alongside the number of words to return (syntax is 'attributeName:nbWords')<br/>By default no snippet is computed.
 * **attributesToIndex**: (array of strings) the list of fields you want to index.<br/>By default all textual attributes of your objects are indexed, but you should update it to get optimal results.<br/>This parameter has two important uses:
  * *Limits the attributes to index*.<br/>For example if you store a binary image in base64, you want to store it and be able to retrieve it but you don't want to search in the base64 string.
  * *Controls part of the ranking*.<br/>Matches in attributes at the beginning of the list will be considered more important than matches in attributes further down the list. 
 * **ranking**: (array of strings) controls the way hits are sorted.<br/>We have five available criteria:
  * **typo**: sort according to number of typos,
  * **geo**: sort according to decreasing distance when performing a geo-location based search,
  * **proximity**: sort according to the proximity of query words in hits, 
  * **attribute**: sort according to the order of attributes defined by **attributesToIndex**,
  * **custom**: sort according to a user defined formula set in **customRanking** attribute.
  <br/>The default order is `["typo", "geo", "proximity", "attribute", "custom"]`. We strongly recommend to keep this configuration.
 * **customRanking**: (array of strings) lets you specify part of the ranking.<br/>The syntax of this condition is an array of strings containing attributes prefixed by asc (ascending order) or desc (descending order) operator.
 For example `"customRanking" => ["desc(population)", "asc(name)"]`
 * **queryType**: select how the query words are interpreted:
  * **prefixAll**: all query words are interpreted as prefixes (default behavior).
  * **prefixLast**: only the last word is interpreted as a prefix. This option is recommended if you have a lot of content to speedup the processing.
  * **prefixNone**: no query word is interpreted as a prefix. This option is not recommended.

You can easily retrieve settings or update them:

```objc
[index getSettings:^(NSDictionary *result) {
    NSLog(@"Settings: %@", result);
} failure:nil];
```

```objc
NSArray *customRanking = [NSArray arrayWithObjects:@"desc(population)", @"asc(name)", nil];
NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:customRanking, @"customRanking", nil];
[index setSettings:settings success:nil failure:nil];

```
List indexes
-------------
You can list all your indexes with their associated information (number of entries, disk size, etc.) with the `listIndexes` method:

```objc
[client listIndexes:^(id result) {
    NSLog(@"Indexes: %@", result);
} failure:nil];
```

Delete an index
-------------
You can delete an index using its name:

```objc
[client deleteIndex:@"cities" success:nil 
  failure:^(ASAPIClient *client, NSString *indexName, NSString *errorMessage) {
    NSLog(@"Could not delete: %@", errorMessage);
}];
```

Wait indexing
-------------

All write operations return a `taskID` when the job is securely stored on our infrastructure but not when the job is published in your index. Even if it's extremely fast, you can easily ensure indexing is complete using the `waitTask` method on the `taskID` returned by a write operation.

For example, to wait for indexing of a new object:
```objc
[index addObject:newObject 
  success:^(ASRemoteIndex *index, NSDictionary *object, NSDictionary *result) {
    // Wait task
    [index waitTask:[result valueForKey:@"objectID"] 
      success:^(ASRemoteIndex *index, NSString *taskID, NSDictionary *result) {
        NSLog(@"New object is indexed");
    } failure:nil];
} failure:nil];
```

If you want to ensure multiple objects have been indexed, you can only check the biggest taskID.

Batch writes
-------------

You may want to perform multiple operations with one API call to reduce latency.
We expose two methods to perform batch:
 * `addObjects`: add an array of object using automatic `objectID` assignement
 * `saveObjects`: add or update an array of object that contains an `objectID` attribute

Example using automatic `objectID` assignement
```objc
NSDictionary *obj1 = [NSDictionary dictionaryWithObjectsAndKeys:@"San Francisco", @"name",
                             [NSNumber numberWithInt:805235], @"population", nil];
NSDictionary *obj2 = [NSDictionary dictionaryWithObjectsAndKeys:@"Los Angeles", @"name",
                             [NSNumber numberWithInt:3792621], @"population", nil];
[index addObjects:[NSArray arrayWithObjects:obj1, obj2, nil] 
  success:^(ASRemoteIndex *index, NSArray *objects, NSDictionary *result) {
    NSLog(@"Object IDs: %@", result);
} failure:nil];
```

Example with user defined `objectID` (add or update):
```objc
NSDictionary *obj1 = [NSDictionary dictionaryWithObjectsAndKeys:@"San Francisco", @"name",
                            [NSNumber numberWithInt:805235], @"population",
                            @"SFO", @"objectID", nil];
NSDictionary *obj2 = [NSDictionary dictionaryWithObjectsAndKeys:@"Los Angeles", @"name",
                            [NSNumber numberWithInt:3792621], @"population",
                            @"LA", @"objectID", nil];
[index saveObjects:[NSArray arrayWithObjects:obj1, obj2, nil] 
  success:^(ASRemoteIndex *index, NSArray *objects, NSDictionary *result) {
    NSLog(@"Object IDs: %@", result);
} failure:nil];
```

Security / User API Keys
-------------

The admin API key provides full control of all your indexes. 
You can also generate user API keys to control security. 
These API keys can be restricted to a set of operations or/and restricted to a given index.

To list existing keys, you can use `listUserKeys` method:
```objc
// Lists global API Keys
[apiClient listUserKeys:^(ASAPIClient *client, NSDictionary *result) {
    NSLog(@"User keys: %@", result);
} failure:nil];
// Lists API Keys that can access only to this index
[index listUserKeys:^(ASRemoteIndex *index, NSDictionary *result) {
    NSLog(@"User keys: %@", result);
} failure:nil];
```

Each key is defined by a set of rights that specify the authorized actions. The different rights are:
 * **search**: allows to search,
 * **addObject**: allows to add/update an object in the index,
 * **deleteObject**: allows to delete an existing object,
 * **deleteIndex**: allows to delete index content,
 * **settings**: allows to get index settings,
 * **editSettings**: allows to change index settings.

Example of API Key creation:
```objc
// Creates a new global API key that can only perform search actions
[apiClient addUserKey:[NSArray arrayWithObject:@"search"] 
  success:^(ASAPIClient *client, NSArray *acls, NSDictionary *result) {
    NSLog(@"API Key:%@", [result objectForKey:@"key"]);
} failure:nil];
// Creates a new API key that can only perform search action on this index
[index addUserKey:[NSArray arrayWithObject:@"search"] 
  success:^(ASRemoteIndex *index, NSArray *acls, NSDictionary *result) {
    NSLog(@"API Key:%@", [result objectForKey:@"key"]);
} failure:nil];
```

You can also create a temporary API key that will be valid only for a specific period of time (in seconds):
```objc
// Creates a new global API key that is valid for 300 seconds
[apiClient addUserKey:[NSArray arrayWithObject:@"search"] withValidity:300 
  success:^(ASAPIClient *client, NSArray *acls, NSDictionary *result) {
    NSLog(@"API Key:%@", [result objectForKey:@"key"]);
} failure:nil];
// Creates a new index specific API key valid for 300 seconds
[index addUserKey:[NSArray arrayWithObject:@"search"] withValidity:300 
  success:^(ASRemoteIndex *index, NSArray *acls, NSDictionary *result) {
    NSLog(@"API Key:%@", [result objectForKey:@"key"]);
} failure:nil];
```

Get the rights of a given key:
```objc
// Gets the rights of a global key
[apiClient getUserKeyACL:@"79710f2fbe18a06fdf12c17a16878654" 
  success:^(ASAPIClient *client, NSString *key, NSDictionary *result) {
    NSLog(@"Key details: %@", result);
} failure:nil];
// Gets the rights of an index specific key
[index getUserKeyACL:@"013464b04012cb73299395a635a2fc6c" 
  success:^(ASRemoteIndex *index, NSString *key, NSDictionary *result) {
    NSLog(@"Key details: %@", result);
} failure:nil];
```

Delete an existing key:
```objc
// Deletes a global key
[apiClient deleteUserKey:@"79710f2fbe18a06fdf12c17a16878654" success:nil 
  failure:^(ASAPIClient *client, NSString *key, NSString *errorMessage) {
    NSLog(@"Delete error: %@", errorMessage);
}];    
// Deletes an index specific key
[index deleteUserKey:@"013464b04012cb73299395a635a2fc6c" success:nil 
  failure:^(ASRemoteIndex *index, NSString *key, NSString *errorMessage) {
   NSLog(@"Delete error: %@", errorMessage);
}]; 
```
