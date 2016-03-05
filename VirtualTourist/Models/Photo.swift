//
//  Photo.swift
//  VirtualTourist
//
//  Created by M on 03/02/16.
//
//

import Foundation
import CoreData
import UIKit
protocol PhotoImageLoadedDelegate {
    func imageLoaded(fromURL url : String?)
    func imageRemoved()
}

class Photo : NSManagedObject {
    @NSManaged var imageURL : String?
    @NSManaged var imageID  : String?
    @NSManaged var pin      : Pin!
    
    var delegate            : PhotoImageLoadedDelegate?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(withPin pin : Pin, imageURL : String, andContext context : NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.pin = pin
        self.imageURL = imageURL
    }
    
    
    var image : UIImage? {
        get {
            return FlickrAPI.Caches.imageCache.imageWithIdentifier(imageID)
        }

        set {
            if newValue != nil {
                FlickrAPI.Caches.imageCache.storeImage(newValue, withIdentifier: imageID!)
                print("[Photo image]: image loaded")
                if delegate == nil {
                    print("Delegate = nil, should only happen if PhotoAlbumVC isn't avilable.")
                }
                delegate?.imageLoaded(fromURL: imageID)
            } else {
                delegate?.imageRemoved()
            }
        }
    }
    
    /*Called before the photo instance is removed from CoreData. This method
    makes sure that the references images are also deleted from the documents directory.*/
    override func prepareForDeletion() {
        FlickrAPI.Caches.imageCache.storeImage(nil, withIdentifier: imageID!)
    }
    
    
    func startLoadingPhotoURL() {
        print("[Photo startLoadingPhotoURL]: \(self) loading url: \(imageURL)")
        if image != nil {
            print("[Photo]: image \(imageID) already available, skipping download")
            delegate?.imageLoaded(fromURL: imageURL)
            return
        }
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        let urlCopyForAvoidingCoreDataAccess = self.imageURL!
        dispatch_async(backgroundQueue) {
            let potentiallyDownloadedData : NSData? = NSData(contentsOfURL: NSURL(string: urlCopyForAvoidingCoreDataAccess)!)
            if let downloadedData = potentiallyDownloadedData {
                let imageFromData = UIImage(data: downloadedData)
                dispatch_async(dispatch_get_main_queue()) {
                    self.image = imageFromData
                }
            }
        }
    }
}