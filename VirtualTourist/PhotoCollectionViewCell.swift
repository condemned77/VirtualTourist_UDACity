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
    
    var photo : Photo? {
        didSet  {
            if let unwrappedPhoto = photo {
                unwrappedPhoto.delegate = self
            } else {
                self.bringSubviewToFront(activityIndicator)
                activityIndicator.startAnimating()
            }
        }
    }
    weak var image : UIImage? {
        set (newImage) {
            self.imageView!.image = newImage
        }
        get {
            return self.imageView!.image
        }
    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    /*Constructor of the PhotoCell.
    If the current instance is missing an assigned imageView, a placeholder
    image is displayed instead.*/
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("PhotoCell instantiating: imageView(\(imageView)) and activityIndicator(\(activityIndicator)) should be instantiated too")
        if let tempImageView = self.imageView {
            if let _ = tempImageView.image {
                showImageView()
            } else {
                self.activityIndicator!.startAnimating()
            }
        } else {
            print("Imageview not available??")
        }
    }
    
    /*Initialiser method for the placeholder image.
    The placehodler image is also somewhat translucient.*/
    func loadPlaceholderImage() {
        image = UIImage(named: "Placeholder")!
        imageView.alpha = 0.3
    }
    
    /*Convenience method that loads the image that is stored in the instance variable photo.
    Also the acitivity indicator, is stopped and removed from the view.*/
    func showImageView() {
        imageView!.image = photo!.photoImage
        self.bringSubviewToFront(imageView)
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    
    /*Implementation of the delegate method of the PhotoImageLoadedDelegate protocol (in the Photo class).
    As soon as the method is invoked, a image has been made available from the Photo instance and is immediately exchanged
    with the currently visible placeholder image.*/
    func imageLoaded() {
        print("[PhotoColectionViewCell]: imageLoaded")
        activityIndicator?.stopAnimating()
        showImageView()
        imageView.alpha = 1.0
    }
}