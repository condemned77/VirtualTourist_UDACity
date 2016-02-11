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
    
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
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
    
    //download new photos
    @IBAction func newCollectionPressed(sender: UIBarButtonItem) {
        self.removeCurrentlyDisplayedImages()
        FlickrAPI.sharedInstance().searchImagesByLatLon(forCoordinates: pinCoordinates) {
            urls, error in
            let newURLs : [String] = self.findNewImageURLs(fromURLArray: urls)
            for (index, imageURL) in newURLs.enumerate() {
                guard index < self.photos.count else {return}

                let photo = self.photos.objectAtIndex(index) as! Photo
                photo.imageURL = imageURL
                photo.startLoadingPhotoURL()
            }
        }
    }
    
    func removeCurrentlyDisplayedImages() {
        for (var idx = 0; idx < photos.count; ++idx) {
            (photos.objectAtIndex(idx) as! Photo).photoImage = nil
        }
    }
    
    func findNewImageURLs(fromURLArray urlArray : [String]) -> [String]{
        var freshImageURLs : [String] = [String]()
        for url in urlArray {
            if urlIsCurrentlyDisplayed(url) {
                continue
            } else {
                freshImageURLs.append(url)
            }
        }
        return freshImageURLs
    }
    
    func urlIsCurrentlyDisplayed(url : String) -> Bool{
        for (var idx = 0; idx < self.photos.count; ++idx) {
            let photo = self.photos.objectAtIndex(idx) as! Photo
            if photo.imageURL == url {
                return true
            }
        }
        return false
    }
    
    
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("collectionView numbersOfItemsInSection")
        if let photos = self.photos {
            print("photo count: \(photos.count)")
            if photos.count > Constants.maxAmountOfPhotos {
                return Constants.maxAmountOfPhotos
            } else {
                return photos.count
            }
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