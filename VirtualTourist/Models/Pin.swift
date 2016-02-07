//
//  Pin.swift
//  VirtualTourist
//
//  Created by M on 26/01/16.
//
//

import Foundation
import MapKit
import CoreData

class Pin : NSManagedObject{
    lazy var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    @NSManaged var photos           : [Photo]
    @NSManaged var longitude        : Double
    @NSManaged var latitude         : Double
    let flickrAPI = FlickrAPI.sharedInstance()
    var coordinates : CLLocationCoordinate2D  {
        set (newCoordinates){
            self.longitude = newCoordinates.longitude
            self.latitude = newCoordinates.latitude
        }
        get {
            let calculatedCoordinates = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            return calculatedCoordinates
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(withCoordiantes coordinates : CLLocationCoordinate2D, andContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.coordinates = coordinates
        self.startFetchingPhotos()
    }
    
    func startFetchingPhotos() {
        flickrAPI.searchByLatLon(forPin: self)
    }
    
    func addImages(fromURLs urls: [NSURL]) {
        for url in urls {
            let photo = Photo(withPin: self, andContext: sharedContext)
            photo.loadPhotoFromURL(url)
            self.photos.append(photo)
        }
    }
}