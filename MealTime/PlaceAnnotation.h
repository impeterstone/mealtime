//
//  PlaceAnnotation.h
//  MealTime
//
//  Created by Peter Shih on 8/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "PSObject.h"

@interface PlaceAnnotation : PSObject <MKAnnotation> {
  NSDictionary *_place;
}

- (id)initWithPlace:(NSDictionary *)place;
- (CLLocationCoordinate2D)coordinate;

@end
