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
    @NSManaged var photos           : [Photo]
    @NSManaged var longitude        : Double
    @NSManaged var latitude         : Double
    let flickrAPI = FlickrAPI.sharedInstance()
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(withCoordiantes coordinates : CLLocationCoordinate2D, andContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.startFetchingPhotosForCoordinates(coordinates)
    }
    
    func startFetchingPhotosForCoordinates(coordinates : CLLocationCoordinate2D) {
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=c70e6c6d0a7ec9000510a4467f050d51b&text=test&format=json&nojsoncallback=1&")!
        let request = NSURLRequest(URL: url)
        
        flickrAPI.searchByLatLon(coordinates)
    }
}