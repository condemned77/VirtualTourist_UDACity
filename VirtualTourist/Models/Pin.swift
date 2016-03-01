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
    func newPhotoInstanceAvailable(photoInstance : Photo);
}

class Pin : NSManagedObject, ImageURLDownloadedDelegate{
    lazy var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    @NSManaged var photos           : NSMutableOrderedSet
    @NSManaged var longitude        : Double
    @NSManaged var latitude         : Double
    @NSManaged var amountOfPages    : Int
    @NSManaged var currentPage      : Int
    
    var oldImageURLs : [String] = [String]()
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
        self.coordinates    = coordinates
        self.currentPage    = 0
        self.amountOfPages  = 0
        self.fetchNewPhotoURLs()
    }
    
    
    /*This method uses the FlickrAPI to download new image urls. A status variable keeps
    track about whether currently image urls are downloaded.*/
    func fetchNewPhotoURLs() -> Bool{
        guard currentlyFetchingPhotoURLs == false else {print("already fetching photo urls."); return false}
        currentlyFetchingPhotoURLs = true
        
        storeAndRemoveOldURLs()
        var pageNum : Int?
        if self.currentPage != 0 {
            pageNum = self.currentPage + 1
            if pageNum > self.amountOfPages {
                self.currentPage = 1
            }
        }
        flickrAPI.searchImagesByLatLon(forCoordinates: coordinates, updateMeForEachURL: self, pageNumber: pageNum) {
            urls, error in
            guard error == nil else {print("error while downloading image urls from flickr: \(error)"); self.currentlyFetchingPhotoURLs = false; return}
            self.currentlyFetchingPhotoURLs = false
        }
        return true
    }
    

    /*Cache all urls of the current photo instances in order to have a refrence,
    when new URLs are available, because duplicate URLs should be avoided.*/
    func storeAndRemoveOldURLs() {
        if self.oldImageURLs.count > 0 {self.oldImageURLs.removeAll()}
        for photo in self.photos {
            let castedPhoto = photo as! Photo
            if castedPhoto.imageURL == nil {
                continue
            }
            self.oldImageURLs.append(castedPhoto.imageURL!)
            castedPhoto.imageURL    = nil
            castedPhoto.imageID     = nil
            castedPhoto.image       = nil
        }
    }
    
    
    /*  Creates new image if necessary, else assign new downloaded imageURL and
    imageID to an existing Photo instance and start downloading the new image.*/
    func newImageURLDownloaded(urlString : String, withPhotoID: String) {
        sharedContext.performBlockAndWait() {
            print("[Pin newImageURLDownloaded: \(urlString) withPhotoID: \(withPhotoID)]")

            if self.photos.count < Constants.maxAmountOfPhotos {
                self.createNewPhoto(withUrl: urlString, andPhotoID: withPhotoID)
            } else {
                print("Handling url: \(urlString)")
                for photo in self.photos {
                    let castedPhoto = photo as! Photo
                    if castedPhoto.imageURL == nil {
                        castedPhoto.imageURL    = urlString
                        castedPhoto.imageID     = withPhotoID
                        castedPhoto.startLoadingPhotoURL()
                        break
                    }
                }
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    
    /*Callback for setting the amount of pages available for a flickr API request.
    This argument is also returned by the flickr API when requesting new images.*/
    func setPageAmountOfLastRequest(pages : Int, currentPage : Int) {
        print("[Pin setPageAmountOfLastRequest]: pages: \(pages) current page: \(currentPage). IsMainThread: \(NSThread.isMainThread())")
//        if let amountOfPages = Int(pages) {
        dispatch_async(dispatch_get_main_queue()) {
            print("Amount of pages for last HTTP request to FlickrAPI: \(pages)")
            self.amountOfPages = pages
//        }
        
//        if let currentPageReturned = Int(currentPage) {
            self.currentPage = currentPage
//        }
            CoreDataStackManager.sharedInstance().saveContext()
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
            self.delegate?.newPhotoInstanceAvailable(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        })
    }
    
    
    /*This method allows for exchanging imageURLs that are currently associented with Photo instances, by passing in
    an array of new imageURLs as type string.*/
    func updateImageURLs(urls : [String]) {
        print("[Pin updateImageURLs]: IsMainThread: \(NSThread.isMainThread())")
        for (index, url) in urls.enumerate() {
            guard index < Constants.maxAmountOfPhotos else {print("[Pin addImageURLs] Amount of displayed photos is limited to \(Constants.maxAmountOfPhotos)"); return}
            (self.photos.objectAtIndex(index) as! Photo).imageURL = url
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
}