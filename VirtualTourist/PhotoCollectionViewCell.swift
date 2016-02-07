//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by M on 06/02/16.
//
//

import Foundation
import UIKit

class PhotoCell : UICollectionViewCell, PhotoDelegate {
    
    var photo : Photo?
    var image : UIImage {
        set (newImage) {
            self.imageView!.image = newImage
        }
        get {
            return self.imageView!.image!
        }
    }
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("PhotoCell instantiating: imageView(\(imageView)) and activityIndicator(\(activityIndicator)) should be instantiated too")
        if let tempImageView = self.imageView {
            if let tempImage = tempImageView.image {
                
            } else {
                self.activityIndicator!.startAnimating()
            }
        } else {
            print("fucking imageview not available??")

        }
    }
    
    
    func imageLoaded() {
        print("PhotoColectionViewCell: imageLoaded")
        image = (photo?.image)!
        self.bringSubviewToFront(imageView!)
        activityIndicator?.stopAnimating()
    }
}