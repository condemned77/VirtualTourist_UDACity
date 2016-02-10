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
    
    @IBOutlet weak var mapView: MKMapView!
    var pinCoordinates : CLLocationCoordinate2D!
    var photos : NSMutableOrderedSet!
    var mapViewRegion : MKCoordinateRegion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pin = MKPointAnnotation()
        pin.coordinate = pinCoordinates
        mapView.region = self.mapViewRegion!
        mapView.addAnnotation(pin)
    }
    
    @IBAction func okButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func newCollectionPressed(sender: UIBarButtonItem) {
        //TODO download new photos
    }
    
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("collectionView numbersOfItemsInSection")
        if let photos = self.photos {
            print("photo count: \(photos.count)")
            return photos.count
        } else {
            return 9 //TODO maybe set to 0
        }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("collectionView cellForItemAtIndexPath")
        let cell : PhotoCell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.contentView.backgroundColor = UIColor.redColor()
        cell.activityIndicator?.startAnimating()
        if indexPath.row < self.photos.count {
            let photo = (self.photos.objectAtIndex(indexPath.row) as! Photo)
            cell.photo = photo
        }
        return cell
    }
    

    internal func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
}