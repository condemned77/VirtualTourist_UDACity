//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by M on 01/02/16.
//
//

import Foundation
import MapKit
import CoreData

class PhotoAlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var associatedPin : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func okButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func newCollectionPressed(sender: UIBarButtonItem) {
        //TODO download new photos
    }
    
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("collectionView numbersOfItemsInSection")
        if let photos = associatedPin?.photos {
            print("photo count: \(photos.count)")
            return photos.count
        } else {
            return 9 //TODO maybe set to 0
        }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:

    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell : PhotoCell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.activityIndicator?.startAnimating()
        if indexPath.row < associatedPin.photos.count {
            associatedPin.photos[indexPath.row].delegate = cell
        }
        return cell
    }
    

    internal func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
}