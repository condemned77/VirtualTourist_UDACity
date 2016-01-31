//
//  MapLocation.swift
//  VirtualTourist
//
//  Created by M on 28/01/16.
//
//

import Foundation
import UIKit
import CoreData
import MapKit

class MapLocation : NSManagedObject {
    @NSManaged var longitude        : NSNumber
    @NSManaged var latitude         : NSNumber
    @NSManaged var latitudeDelta    : NSNumber
    @NSManaged var longitudeDelta   : NSNumber
    
    var mapRegion : MKCoordinateRegion {
        get {
            let long : CLLocationDegrees        = CLLocationDegrees(self.longitude.doubleValue)
            let lat : CLLocationDegrees         = CLLocationDegrees(self.latitude.doubleValue)
            let longDelta : CLLocationDegrees   = CLLocationDegrees(self.longitudeDelta.doubleValue)
            let latDetla : CLLocationDegrees    = CLLocationDegrees(self.latitudeDelta.doubleValue)
            
            let coordinate                  = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let span                        = MKCoordinateSpan(latitudeDelta: latDetla, longitudeDelta: longDelta)
            let region : MKCoordinateRegion = MKCoordinateRegion(center: coordinate, span: span)
            return region
        }
        
        set (newMapRegion){
            self.longitude      = newMapRegion.center.longitude
            self.latitude       = newMapRegion.center.latitude
            self.longitudeDelta = newMapRegion.span.latitudeDelta
            self.latitudeDelta  = newMapRegion.span.longitudeDelta
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinateRegion : MKCoordinateRegion, andContext context : NSManagedObjectContext) {
        let entity : NSEntityDescription = NSEntityDescription.entityForName("MapLocation", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.mapRegion = coordinateRegion
    }
}