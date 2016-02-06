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

class Photo : NSManagedObject {
    @NSManaged var imageData : NSData?
    @NSManaged var pin : Pin?
    
    var image : UIImage? = nil
    
    func loadPhotoFromURL(imageURL : NSURL) {
        if  let imageData : NSData = NSData(contentsOfURL: imageURL) {
            dispatch_async(dispatch_get_main_queue(), {
                self.image = UIImage(data: imageData)
            })
        }
    }
}