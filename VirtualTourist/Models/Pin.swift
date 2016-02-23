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
    
    /*A pin can only be instantiated by providing coordinates.
    Also an instantiation automatically triggeres downloading of new image urls from Flickr.*/
    init(withCoordiantes coordinates : CLLocationCoordinate2D, andContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.coordinates = coordinates
        self.fetchNewPhotoURLs()
    }
    
    
    /*This method uses the FlickrAPI to download new image urls. A status variable keeps
    track about whether currently image urls are downloaded.*/
    func fetchNewPhotoURLs() -> Bool{
        guard currentlyFetchingPhotoURLs == false else {print("already fetching photo urls."); return false}
        currentlyFetchingPhotoURLs = true
        flickrAPI.searchImagesByLatLon(forCoordinates: coordinates, updateMeForEachURL: self) {
            urls, error in
            guard error == nil else {print("error while downloading image urls from flickr: \(error)"); self.currentlyFetchingPhotoURLs = false; return}
            self.currentlyFetchingPhotoURLs = false
        }
        return true
    }
    
    /*  Creates new image if necessary, else don't care for instantiation
        and just wait for the rest of urls to be downloaded and update images
        later. 
    */
    func newImageURLDownloaded(urlString : String, withPhotoID: String) {
        sharedContext.performBlockAndWait() {
            if self.photos.count < Constants.maxAmountOfPhotos {
                self.createNewPhoto(withUrl: urlString, andPhotoID: withPhotoID)
            }
        }
    }
    
    
    /*This method creates new Photo instances and assigns image urls stored in its argument.*/
//    func addImageURLs(urls: [String]) {
//        for (index, url) in urls.enumerate() {
//            guard index < Constants.maxAmountOfPhotos else {print("[Pin addImageURLs] Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
//            createNewPhoto(withUrl: url)
//        }
//    }
    
    
    /*Convenience method for creating a new Photo instance. By design, each Pin instance can only hold
    21 Photo instances. A Photo instance can only be created with an imageURL (type: String).
    After a Photo instance has been created it is stored in the instance variable photos, followed by
    saving the core data context, and thus persisting the Photo instance.
    */
    func createNewPhoto(withUrl urlString : String, andPhotoID photoID : String) {
        print("[Pin createNewImage]: pin is holding \(photos.count) Photos. (shouldn't be over \(Constants.maxAmountOfPhotos))")
        guard photos.count < Constants.maxAmountOfPhotos else {print("[Pin createNewImage] Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
        sharedContext.performBlockAndWait({
            let photo = Photo(withPin: self, imageURL: urlString, andContext: self.sharedContext)
            print("created new Photo instance with URL: \(urlString) ")
            photo.imageID = photoID
            photo.startLoadingPhotoURL()
            self.photos.addObject(photo)
            self.delegate?.newPhotoInstancesAvailable()
            CoreDataStackManager.sharedInstance().saveContext()
        })
    }
    
    
    /*This method allows for exchanging imageURLs that are currently associented with Photo instances, by passing in
    an array of new imageURLs as type string.*/
    func updateImageURLs(urls : [String]) {
        for (index, url) in urls.enumerate() {
            guard index < Constants.maxAmountOfPhotos else {print("[Pin addImageURLs] Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
            (self.photos.objectAtIndex(index) as! Photo).imageURL = url
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
}