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
protocol PhotoDelegate {
    func imageLoaded()
}

class Photo : NSManagedObject {
    @NSManaged var imageURL : String?
    @NSManaged var pin : Pin?
    var delegate : PhotoDelegate?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(withPin pin : Pin, andContext context : NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.pin = pin
    }
    
    var image : UIImage? = nil {
        didSet {
            print("image loaded")
            delegate?.imageLoaded()
        }
    }
    
    func loadPhotoFromURL(imageURL : NSURL) {
        self.imageURL = imageURL.absoluteString
        if  let downloadedData : NSData = NSData(contentsOfURL: imageURL) {
            dispatch_async(dispatch_get_main_queue(), {
                self.image = UIImage(data: downloadedData)
                self.photoImage = self.image
            })
        }
    }
    
    var photoImage: UIImage? {
        
        get {
            return FlickrAPI.Caches.imageCache.imageWithIdentifier(imageURL)
        }
        
        set {
            FlickrAPI.Caches.imageCache.storeImage(newValue, withIdentifier: imageURL!)
        }
    }

}