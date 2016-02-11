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
    
    @NSManaged var photos           : NSMutableOrderedSet
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
        self.fetchNewPhotos()
    }
    
    func fetchNewPhotos() {
        flickrAPI.searchImagesByLatLon(forCoordinates: coordinates) {
            urls, error in
            guard error == nil else {print("error while downloading image urls from flickr: \(error)"); return}
            for (index, url) in urls.enumerate() {
                (self.photos.objectAtIndex(index) as! Photo).imageURL = url
            }
        }
    }
    
    func addImages(fromURLs urls: [String]) {
        for (index, url) in urls.enumerate() {
            guard index < Constants.maxAmountOfPhotos else {print("Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
            let photo = Photo(withPin: self, andContext: sharedContext)
            photo.imageURL = url
            self.photos.addObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
}