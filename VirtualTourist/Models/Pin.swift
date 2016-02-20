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

protocol NewPhotoInstancesAvailableDelegate {
    func newPhotoInstancesAvailable();
}

class Pin : NSManagedObject, ImageURLDownloadedDelegate{
    lazy var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    @NSManaged var photos           : NSMutableOrderedSet
    @NSManaged var longitude        : Double
    @NSManaged var latitude         : Double
    
    var delegate : NewPhotoInstancesAvailableDelegate?
    var currentlyFetchingPhotoURLs = false
    
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
        self.fetchNewPhotoURLs()
    }
    
    
    func fetchNewPhotoURLs() -> Bool{
        guard currentlyFetchingPhotoURLs == false else {print("already fetching photo urls."); return false}
        currentlyFetchingPhotoURLs = true
        flickrAPI.searchImagesByLatLon(forCoordinates: coordinates, updateMeForEachURL: self) {
            urls, error in
            guard error == nil else {print("error while downloading image urls from flickr: \(error)"); self.currentlyFetchingPhotoURLs = false; return}
//            for (index, url) in urls.enumerate() {
//                guard index < self.photos.count else {return}
//                (self.photos.objectAtIndex(index) as! Photo).imageURL = url
//            }
            self.currentlyFetchingPhotoURLs = false
        }
        return true
    }
    
    /*  Creates new image if necessary, else don't care for instantioation
        and just wait for the rest of urls to be downloaded and update images
        later. 
    */
    func newImageURLDownloaded(urlString : String) {
        if photos.count < Constants.maxAmountOfPhotos {
            createNewImage(withUrl: urlString)
        }
    }
    
    
    func addImageURLs(urls: [String]) {
        for (index, url) in urls.enumerate() {
            guard index < Constants.maxAmountOfPhotos else {print("[Pin addImageURLs] Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
            createNewImage(withUrl: url)
        }
    }
    
    
    func createNewImage(withUrl urlString : String) {
        print("[Pin createNewImage]: pin is holding \(photos.count) Photos. (shouldn't be over \(Constants.maxAmountOfPhotos))")
        guard photos.count < Constants.maxAmountOfPhotos else {print("[Pin createNewImage] Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
        let photo = Photo(withPin: self, andContext: sharedContext)
        photo.imageURL = urlString
        photo.startLoadingPhotoURL()
        photos.addObject(photo)
        delegate?.newPhotoInstancesAvailable()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    func updateImageURLs(urls : [String]) {
        for (index, url) in urls.enumerate() {
            guard index < Constants.maxAmountOfPhotos else {print("[Pin addImageURLs] Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
            (self.photos.objectAtIndex(index) as! Photo).imageURL = url
        }
    }
}