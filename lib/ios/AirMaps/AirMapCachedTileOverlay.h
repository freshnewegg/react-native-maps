//
//  AirMapCachedTileOverlay.h
//  AirMaps
//
//  Created by Edgar Wang on 2017-07-31.
//  Copyright © 2017 Christopher. All rights reserved.
//

#ifndef AirMapCachedTileOverlay_h
#define AirMapCachedTileOverlay_h

#import <MapKit/MapKit.h>

#import "RCTConvert+MapKit.h"
#import "RCTComponent.h"

@class AIRMapCachedTileOverlay;

@interface AIRMapCachedTileOverlay : MKTileOverlay

@property (strong, nonatomic) NSString *tileCachePath;

- (void)clearCache;

@end


#endif /* AirMapCachedTileOverlay_h */
