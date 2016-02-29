//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by M on 06/02/16.
//
//

import Foundation
import UIKit

class PhotoCell : UICollectionViewCell, PhotoImageLoadedDelegate {
    let placeholder : UIImage = UIImage(named: "Placeholder")!
    var photo : Photo? {
        didSet  {
            if let unwrappedPhoto = photo {
                unwrappedPhoto.delegate = self
                if let _ = photo?.image {
                    showImageOfPhotoInstance()
                }
                else {
                    loadPlaceholderImage()
                }
            }
        }
    }
//    weak var image : UIImage? {
//        set (newImage) {
//            print("[PhotoCell setImage] new image: \(newImage)")
//            self.imageView!.image = newImage
//            if newImage == nil {loadPlaceholderImage()}
//            if newImage != placeholder {
//                activityIndicator.stopAnimating()
//                activityIndicator.removeFromSuperview()
//            }
//        }
//        get {
//            return self.imageView!.image
//        }
//    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    /*Constructor of the PhotoCell.
    If the current instance is missing an assigned imageView, a placeholder
    image is displayed instead.*/
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    /*Initialiser method for the placeholder image.
    The placeholder image is also somewhat translucent.*/
    func loadPlaceholderImage() {
        print("[PhotoCell loadPlaceholderImage]")

        dispatch_async(dispatch_get_main_queue()) {
            print("image before placeholder: \(self.imageView.image)")
            self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
            self.imageView.image = self.placeholder
            print("image after placeholder: \(self.imageView.image)")
            self.addSubview(self.imageView)
            self.bringSubviewToFront(self.imageView)
            self.imageView.alpha = 0.3
            self.imageView.addSubview(self.activityIndicator)
            self.activityIndicator.startAnimating()
            self.imageView.addSubview(self.activityIndicator)
            if self.activityIndicator.hidden == true {
                self.activityIndicator.hidden = false
            }
            self.activityIndicator.hidesWhenStopped = true
        }
    }
    
    
    /*Convenience method that loads the image that is stored in the instance variable photo.
    Also the activity indicator, is stopped and removed from the view.*/
    func showImageOfPhotoInstance() {
        print("[PhotoCell showImageOfPhotoInstance]")
        imageView!.contentMode  = UIViewContentMode.ScaleAspectFit
        imageView!.image        = photo!.image
        print("image size: \(imageView.image?.size)")
        bringSubviewToFront(imageView)
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        imageView.alpha         = 1.0
    }
    
    
    /*Implementation of the delegate method of the PhotoImageLoadedDelegate protocol (in the Photo class).
    As soon as the method is invoked, a image has been made available from the Photo instance and is immediately exchanged
    with the currently visible placeholder image.*/
    func imageLoaded(fromURL url : String?) {
        print("[PhotoCell imageLoaded]: \(url)")
        showImageOfPhotoInstance()
    }
    
    /*This callack method is part of the PhotoImageLoadedDelegate protocol and is invoked when the Photo instance's
    image set to nil. In this case, the cell that is still displaying the image, should display a placeholder image
    in order to show that no current image is available.*/
    func imageRemoved() {
        print("[PhotoCell imageRemoved]: imageView.image: \(imageView.image)")
        imageView.image = nil
        imageView.removeFromSuperview()
        loadPlaceholderImage()
    }
}