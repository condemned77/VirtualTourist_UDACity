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
        print("image before placeholder: \(imageView.image)")
        imageView.image = placeholder
        bringSubviewToFront(imageView)
        print("image after placeholder: \(imageView.image)")
        imageView.alpha = 0.3
        imageView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        imageView.addSubview(activityIndicator)
        if activityIndicator.hidden == true {
            activityIndicator.hidden = false
        }
        activityIndicator.hidesWhenStopped = true
    }
    
    /*Convenience method that loads the image that is stored in the instance variable photo.
    Also the activity indicator, is stopped and removed from the view.*/
    func showImageOfPhotoInstance() {
        print("[PhotoCell showImageOfPhotoInstance]")
        imageView!.image = photo!.image
        bringSubviewToFront(imageView)
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    
    /*Implementation of the delegate method of the PhotoImageLoadedDelegate protocol (in the Photo class).
    As soon as the method is invoked, a image has been made available from the Photo instance and is immediately exchanged
    with the currently visible placeholder image.*/
    func imageLoaded() {
        print("[PhotoCell imageLoaded]")
        showImageOfPhotoInstance()
        imageView.alpha = 1.0
    }
    
    /*This callack method is part of the PhotoImageLoadedDelegate protocol and is invoked when the Photo instance's
    image set to nil. In this case, the cell that is still displaying the image, should display a placeholder image
    in order to show that no current image is available.*/
    func imageRemoved() {
        print("[PhotoCell imageRemoved]")
        imageView.image = nil
        imageView.removeFromSuperview()
        loadPlaceholderImage()
    }
}