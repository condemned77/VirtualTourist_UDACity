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
    @NSManaged var longitude : Double
    @NSManaged var latitude : Double
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate : CLLocationCoordinate2D, andContext context : NSManagedObjectContext) {
        let entity : NSEntityDescription = NSEntityDescription.entityForName("MapLocation", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        longitude   = coordinate.longitude
        latitude    = coordinate.latitude
    }
}