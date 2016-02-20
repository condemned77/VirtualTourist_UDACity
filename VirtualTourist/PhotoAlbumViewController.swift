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

class PhotoAlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
    var pin : Pin!
    var pinCoordinates : CLLocationCoordinate2D!
//    weak var photos : NSMutableOrderedSet!
    var mapViewRegion : MKCoordinateRegion?
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchreq = NSFetchRequest(entityName: "Photo")
        fetchreq.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        fetchreq.predicate = NSPredicate(format: "pin==%@", self.pin)
        
        let ctrl = NSFetchedResultsController(fetchRequest: fetchreq, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        ctrl.delegate = self
        return ctrl
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[PhotoAlbumVC viewDidLoad]")
        let mapAnnotation = MKPointAnnotation()
        mapAnnotation.coordinate = pin.coordinates
        mapView.region = self.mapViewRegion!
        mapView.addAnnotation(mapAnnotation)

        do {
            try self.fetchedResultsController.performFetch()
        } catch let error {
            print("error: \(error)")
        }
    }
    
    func newPhotoInstancesAvailable() {

    }
    
    @IBAction func okButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //download new photos
    @IBAction func newCollectionPressed(sender: UIBarButtonItem) {
        self.removeCurrentlyDisplayedImages()
        FlickrAPI.sharedInstance().searchImagesByLatLon(forCoordinates: pinCoordinates, updateMeForEachURL: nil) {
            urls, error in
            
            let sectionInfo : NSFetchedResultsSectionInfo = self.fetchedResultsController.sections![0]
            let amountOfPhoto = sectionInfo.numberOfObjects
            
            let newURLs : [String] = self.findNewImageURLs(fromURLArray: urls)
            for (index, imageURL) in newURLs.enumerate() {
                guard index < amountOfPhoto else {return}
                let indexPath = NSIndexPath(index: index)
                let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
                photo.imageURL = imageURL
                dispatch_async(dispatch_get_main_queue()) {
                    photo.startLoadingPhotoURL()
                }
            }
            self.collectionView.reloadData()
        }
    }
    
    
    func removeCurrentlyDisplayedImages() {
        let sectionInfo : NSFetchedResultsSectionInfo = self.fetchedResultsController.sections![0]
        let amountOfPhoto = sectionInfo.numberOfObjects

        for (var idx = 0; idx < amountOfPhoto; ++idx) {
            guard idx < amountOfPhoto else {return}
            let indexPath = NSIndexPath(index: idx)
            let photo = (fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
            photo.photoImage = nil
        }
        collectionView.reloadData()
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
        let sectionInfo : NSFetchedResultsSectionInfo = self.fetchedResultsController.sections![0]
        let amountOfPhoto = sectionInfo.numberOfObjects

        for (var idx = 0; idx < amountOfPhoto; ++idx) {
            guard idx < amountOfPhoto else {return false}
            let indexPath = NSIndexPath(index: idx)
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            if photo.imageURL == url {
                return true
            }
        }
        return false
    }
    
    
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("[PhotoAlbumViewController collectionView numbersOfItemsInSection]")
        let sectionInfo : NSFetchedResultsSectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("collectionView cellForItemAtIndexPath")
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let cell : PhotoCell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        configureCell(cell, photo: photo)
    
        return cell
    }
    
    func configureCell(cell : PhotoCell, photo : Photo) {
        if cell.image == nil {
            cell.loadPlaceholderImage()
        }
        cell.activityIndicator?.startAnimating()
        photo.startLoadingPhotoURL()
        cell.photo = photo
    }

    internal func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {

    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            self.collectionView.insertSections(NSIndexSet(index: sectionIndex))
            break
        case .Delete:
            self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
            
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        print("didChangeObject: \(anObject) atIndexPath: \(indexPath) forChangeType: \(type) newIndexPath: \(newIndexPath)")
        
        switch type {
        case .Insert:
            self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
            break
        case .Delete:
            self.collectionView.deleteItemsAtIndexPaths([indexPath!])
        case .Move:
            self.collectionView.deleteItemsAtIndexPaths([indexPath!])
            self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
        case .Update:
//            let photo = self.fetchedResultsController.objectAtIndexPath(indexPath!) as! Photo
//            let cell = self.collectionView.cellForItemAtIndexPath(indexPath!) as! PhotoCell
            self.collectionView.insertItemsAtIndexPaths([indexPath!])
        }
    }

}