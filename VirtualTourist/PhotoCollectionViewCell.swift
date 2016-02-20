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
    var image : UIImage? {
        set (newImage) {
            self.imageView!.image = newImage
        }
        get {
            return self.imageView!.image
        }
    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
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
    
    func loadPlaceholderImage() {
        image = UIImage(named: "Placeholder")!
        imageView.alpha = 0.3
    }
    
    func showImageView() {
        imageView!.image = photo!.photoImage
        self.bringSubviewToFront(imageView)
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    
    func imageLoaded() {
        print("[PhotoColectionViewCell]: imageLoaded")
        activityIndicator?.stopAnimating()
        showImageView()
        imageView.alpha = 1.0
    }
}