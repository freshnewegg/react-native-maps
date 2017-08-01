//
//  AirMapCachedTileOverlay.m
//  AirMaps
//
//  Created by Edgar Wang on 2017-07-31.
//  Copyright © 2017 Christopher. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AIRMapCachedTileOverlay.h"

#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@implementation AIRMapCachedTileOverlay

#define kMaxCacheItemAge -45 * 24 * 60 * 60

- (instancetype)init
{
    return [super init];
}

// we clear old cache entries every time we start up.
- (void)clearCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *tilePathUrl = [[NSURL alloc] initFileURLWithPath:self.tileCachePath];
        NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
        
        NSDirectoryEnumerator *enumerator = [fileManager
                                             enumeratorAtURL:tilePathUrl
                                             includingPropertiesForKeys:keys
                                             options:0
                                             errorHandler:^(NSURL *url, NSError *error) {
                                                 NSLog(@"Error building enumerator.");
                                                 return YES;
                                             }];
        
        for (NSURL *url in enumerator) {
            NSError *error;
            NSNumber *isDirectory = nil;
            if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                NSLog(@"Error testing for directory.");
            }
            else if (![isDirectory boolValue]) {
                NSString *path = [url path];
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:[url path] error:nil];
                if ([[attributes fileModificationDate] timeIntervalSinceNow] < kMaxCacheItemAge) {
                    NSLog(@"deleting old cache item: %s", path);
                    [fileManager removeItemAtPath:path error:&error];
                }
            }
        }
    });
}

typedef void (^tilecallback)(NSData *tileData, NSError *connectionError);
- (void)loadTileAtPath:(MKTileOverlayPath)path result:(tilecallback)result
{
    NSError *error;
    
    if (!self.tileCachePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        self.tileCachePath = [NSString stringWithFormat:@"%@/tileCache", documentsDirectory];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.tileCachePath])
            [[NSFileManager defaultManager] createDirectoryAtPath:self.tileCachePath withIntermediateDirectories:NO attributes:nil error:&error];
        
        [self clearCache];
    }
    
    NSString* tileCacheFileDirectory = [NSString stringWithFormat:@"%@/%d/%d", self.tileCachePath, path.z, path.x];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tileCacheFileDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:tileCacheFileDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSString* tileCacheFilePath = [NSString stringWithFormat:@"%@/%d", tileCacheFileDirectory, path.y];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tileCacheFilePath]) {
        NSLog(@"tile cache MISS for %d_%d_%d", path.z, path.x, path.y);
        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (result) result(data, connectionError);
            if (!connectionError) [[NSFileManager defaultManager] createFileAtPath:tileCacheFilePath contents:data attributes:nil];
        }];
    } else {
        NSLog(@"tile cache HIT for %d_%d_%d", path.z, path.x, path.y);
        
        // If we use a tile, update its modified time so that our cache is purging only unused items.
        if (![[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:[NSDate date]}
                                              ofItemAtPath:tileCacheFilePath
                                                     error:&error]) {
            NSLog(@"Couldn't update modification date: %@", error);
        }
        
        NSData* tile = [NSData dataWithContentsOfFile:tileCacheFilePath];
        if (result) result(tile, nil);
    }
}

@end
