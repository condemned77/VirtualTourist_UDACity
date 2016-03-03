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

class PhotoAlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, NewPhotoInstancesAvailableDelegate {

    @IBOutlet weak var noPhotosLabel    : UILabel?
    @IBOutlet weak var mapView          : MKMapView!
    @IBOutlet weak var collectionView   : UICollectionView!
    @IBOutlet weak var bottomButton     : UIBarButtonItem!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searching through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths  : [NSIndexPath]!
    var deletedIndexPaths   : [NSIndexPath]!
    var updatedIndexPaths   : [NSIndexPath]!
    var movedIndexPaths     : [NSIndexPath : NSIndexPath]!

    var pin : Pin!
    var mapViewRegion : MKCoordinateRegion?
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchreq = NSFetchRequest(entityName: "Photo")
        fetchreq.sortDescriptors = []//NSSortDescriptor(key: "imageURL", ascending: true)]
        fetchreq.predicate = NSPredicate(format: "pin==%@", self.pin)
        
        let ctrl = NSFetchedResultsController(fetchRequest: fetchreq, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        ctrl.delegate = self
        return ctrl
    }()

    
    /*Convenience variable for accessing the amount of Photo instances associated to the
    currently considered Pin instance.*/
    var amountOfPhotos : Int {
        var sectionInfo : NSFetchedResultsSectionInfo!
        var amountOfPhotosInContext : Int = 0
        sharedContext.performBlockAndWait {
            sectionInfo = self.fetchedResultsController.sections![0]
            amountOfPhotosInContext = sectionInfo.numberOfObjects
        }
        return amountOfPhotosInContext
    }
    
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        // Lay out the collection view so that cells take up 1/3 of the width,
//        // with no space in between.
//        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        layout.minimumLineSpacing = 0
//        layout.minimumInteritemSpacing = 0
//        
//        let width = floor(self.collectionView.frame.size.width/3)
//        layout.itemSize = CGSize(width: width, height: width)
//        collectionView.collectionViewLayout = layout
//    }

    
    /*When the view is loaded, the mapview instance of this viewController is centered 
    to the coordinates of the Pin instance associated.
    Then the NSFetchedResultsController is used to grasp all Photo instances associated to this Pin.
    If no Photo instances are available, the Pin instance is told to load the images that belong to these Photo instances.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[PhotoAlbumVC viewDidLoad]")
        let mapAnnotation = MKPointAnnotation()
        mapAnnotation.coordinate = pin.coordinates
        mapView.region = self.mapViewRegion!
        mapView.addAnnotation(mapAnnotation)

        do {
            try self.fetchedResultsController.performFetch()

            if amountOfPhotos == 0 {
                toggleNoPhotosLabel()
                pin.fetchNewPhotoURLs()
            } else { //cover the case that photo cells are empty/show placeholder and images aren't being downlaoded
                dispatch_async(dispatch_get_main_queue()){
                    for photo in self.pin!.photos {
                        let castedPhoto = photo as! Photo
                        if castedPhoto.image == nil && castedPhoto.imageURL != nil{
                            castedPhoto.startLoadingPhotoURL()
                        }
                    }
                }
            }
            
        } catch let error {
            print("error: \(error)")
        }
    }
    
    
    /*Convenience method for toggling between displaying a label that says: "No Photos available"
    and removing the label from this viewController.*/
    func toggleNoPhotosLabel() {
        if amountOfPhotos == 0 {
            if let labelShouldBeThere = noPhotosLabel {
                view.addSubview(labelShouldBeThere)
            }
        } else {
            noPhotosLabel?.removeFromSuperview()
        }
    }
    
    
    //IBAction method to dismiss this viewController.
    @IBAction func okButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    /*Callback method for when the bottom button is pressed.
    Based on whether a image has been selected, the method flow
    decides whether a new image collection should be downloaded or
    the selected image(s) should be deleted from the current view.
    */
    @IBAction func bottomButtonPressed(sender: UIBarButtonItem) {
        print("[PhotoAlbumViewController bottomButtonPressed] IsMainThread: \(NSThread.isMainThread())")
        if selectedIndexes.isEmpty {
            loadNewImageCollection()
        } else {
            deleteSelectedImages()
        }
    }
    
    
    /*Calling this method method removes all currently displayed images and 
    loads new ones.*/
    func loadNewImageCollection() {
        print("[PhotoAlbumViewController loadImageCollection] IsMainThread: \(NSThread.isMainThread())")
//        guard amountOfPhotos > 0 else {print("no photos available for refresh"); return}
        removeCurrentlyDisplayedImages()
        loadNewImages()
    }
    
    
    /*This method first grabs all Photo
    instances by using the NSFetchedResultsController and the the instance
    variable selectedIndexes. Then each of the grabbed Photo instances is
    delete from the shared context.
    */
    func deleteSelectedImages() {
        print("[PhotoAlbumViewController deleteSelectedImages] IsMainThread: \(NSThread.isMainThread())")
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        sharedContext.performBlockAndWait() {
            for photo in photosToDelete {
                self.sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        selectedIndexes = [NSIndexPath]()
        toggleBottomButtonTitle()
    }
    
    
    /*This method asks the Flickr API to search and download new image URLs based on the coordinates of the
    Pin assigned to this viewController instance. After the download was successful, the new image urls
    are assigned to the Photo instances on the Pin. In turn, the photo instances communicate with their
    delegates, i.e. the PhotoCell instances when an image is ready for display.*/
    func loadNewImages() {
        print("[PhotoAlbumViewController loadNewImages] IsMainThread: \(NSThread.isMainThread())")
        pin.fetchNewPhotoURLs()
    }
    
    
    /*This method iterates over the currently available amount of Photo instances
    and sets their photoImage instance variable to nil in order to delete the
    associated image.
    */
    func removeCurrentlyDisplayedImages() {
        for (var idx = 0; idx < amountOfPhotos; ++idx) {
            let indexPath = NSIndexPath(forRow: idx, inSection: 0)
            let photo = (fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
            if photo.imageID != nil {
                FlickrAPI.Caches.imageCache.storeImage(nil, withIdentifier: photo.imageID!)
            }
        }
    }
    
    
    /*This method takes the URLs contained in the urlArray and comapares each url
    with the urls of images that are currenly displayed in the collection view.
    Due to this, it should be avoided that photos are displayed that are currently 
    visible.*/
    func findNewImageURLs(fromURLDict urlDict : [String : String]) -> [String : String]{
        var freshImageURLs : [String : String] = [String : String]()
        for (imageID, url) in urlDict {
            guard freshImageURLs.count < amountOfPhotos else {print("\(amountOfPhotos) new urls are enough, stopping to find more new urls."); break}
            if urlIsCurrentlyDisplayed(url) {
                continue
            } else {
                freshImageURLs[imageID] = url
            }
        }
        return freshImageURLs
    }
    
    
    /*This method takes a url string and compares it to the urls of images that are currently displayed.
    If a passed in url string is already displayed (as an image) then true is returned, else false.*/
    func urlIsCurrentlyDisplayed(url : String) -> Bool{
        
        for (var idx = 0; idx < amountOfPhotos; ++idx) {
            guard idx < amountOfPhotos else {return false}
            let indexPath = NSIndexPath(forRow: idx, inSection: 0)
            var imageURL : String!
            sharedContext.performBlockAndWait() {
                imageURL = (self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo).imageURL
            }
            
            if imageURL == url {
                return true
            }
        }
        return false
    }
    
    
    /*Callback method that return the amount of photos currently associates to this viewController.*/
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("[PhotoAlbumViewController collectionView numbersOfItemsInSection] IsMainThread: \(NSThread.isMainThread())")
        if amountOfPhotos > 0 {toggleNoPhotosLabel()}
//        return Constants.maxAmountOfPhotos
        return self.pin!.photos.count
    }
    
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("[collectionView cellForItemAtIndexPath] IsMainThread: \(NSThread.isMainThread())")
        let cell : PhotoCell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell

        configureCell(cell, atIndexPath: indexPath)
        cell.backgroundColor = UIColor.redColor()
        return cell
    }
    
    
    /*Callback method that is called if a cell of the collection view is touched. If so, the 
    cell is visually marked, by changing it's alpha value. If a cell is selected it's possible to 
    delete it by pressing a button at the bottom of the view, which will be activated as soon
    as any cell is touched. This button will be activated by calling the method toggleBottomButtonTitle*/
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard amountOfPhotos != 0 else {print("No photo instances available, don't mark cells."); return}
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        print("[PhotoAlbumVC didSelectItem]: imagesize: \(cell.imageView.image?.size), cell size: \(cell.frame.size) with url: \(cell.photo?.imageURL) on position: \(indexPath.row) IsMainThread: \(NSThread.isMainThread())")
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the bottom button
        toggleBottomButtonTitle()
    }
    
    
    /*This method changes the title of the button located at the bottom of the viewController.
    The title is based on whether a cell is touched by the user or not. If at least on cell is touched,
    the content of selectedIndexes is > 0.*/
    func toggleBottomButtonTitle() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    
    /*Convenience method for configuring a cell of the UICollectionView instance.
    This method sets a photo instance to the cell, in order fro the cell to display
    an image, if one is present in the photo instance. 
    In case a user has touched a cell, the index path of such a cell is stored in
    the selctedIndexes array. In such case, the alpha variable of a cell is changed,
    in order to visually indicate that it has been marked by the user (for deletion).*/
    func configureCell(cell : PhotoCell, atIndexPath indexPath : NSIndexPath) {
        print("[PhotoAlbumViewController configureCell] IsMainThread: \(NSThread.isMainThread())")
        print("amount of photos: \(amountOfPhotos), requested row: \(indexPath.row)")
        guard indexPath.row < amountOfPhotos else {print("requested row: \(indexPath.row) has to be smaller than \(amountOfPhotos)"); return}
        if amountOfPhotos == 0 {
            print("No photo instances available yet.");
            self.toggleNoPhotosLabel();
            return
        } else {
//            if cell.photo == nil {
                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
                cell.photo = photo
//            } else {
//                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
//                print("PhotoCell has already a photo instance assigned. This instance should be equal to: \(photo)")
//                print("photo of cell: \(cell.photo), supposingly the same photo instance: \(photo)===> the same? \(cell.photo == photo)")
            //}
            if let _ = selectedIndexes.indexOf(indexPath) {
                cell.alpha = 0.30
            } else {
                cell.alpha = 1.0
            }
        }
    }

    
    //Callback method of UICollectionViewDataSource
    //In this app we only work with one section.
    internal func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func newPhotoInstanceAvailable(photoInstance : Photo) {
        print("[PhotoAlbumViewController newPhotoInstanceAvailable]: IsMainThread: \(NSThread.isMainThread())")
        let indexPath = fetchedResultsController.indexPathForObject(photoInstance)
        let associatedCell = collectionView.cellForItemAtIndexPath(indexPath!) as! PhotoCell
        configureCell(associatedCell, atIndexPath: indexPath!)
    }
    
    
    //MARK: NSFetchedResultsControllerDelegate method implementation
    //Callback method of NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("[PhotoAlbumViewController controllerWillChangeContent]")
        insertedIndexPaths  = [NSIndexPath]()
        deletedIndexPaths   = [NSIndexPath]()
        updatedIndexPaths   = [NSIndexPath]()
        movedIndexPaths     = [NSIndexPath : NSIndexPath]()
    }
    
    
    //Callback method of NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("[PhotoAlbumViewController controllerDidChangeContent] changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count). IsMainThread: \(NSThread.isMainThread())")
        
        collectionView.performBatchUpdates({() -> Void in
            print("[PhotoAlbumViewController controllerDidChangeContent] IsMainThread: \(NSThread.isMainThread())")
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }

            CoreDataStackManager.sharedInstance().saveContext()
            }, completion: nil)
    }
    
    
    //Callback method of NSFetchedResultsControllerDelegate
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        print("[PhotoAlbumViewController didChangeSection] IsMainThread: \(NSThread.isMainThread())")
        switch type {
        case .Insert:
            self.collectionView.insertSections(NSIndexSet(index: sectionIndex))
            break
        case .Delete:
            self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
            break
        default:
            return
        }
    }
    
    
    //Callback method of NSFetchedResultsControllerDelegate
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue()) {
        print("didChangeObject: \(anObject) atIndexPath: \(indexPath) forChangeType: \(type.rawValue) newIndexPath: \(newIndexPath). IsMainThread: \(NSThread.isMainThread())")
        }
        
        switch type {
        case .Insert:
            print("Insert(\(type.rawValue)) an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete(\(type.rawValue)) an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move(\(type.rawValue)) an item. From index path: \(indexPath) to newIndexPath: \(newIndexPath)")
            movedIndexPaths[indexPath!] = newIndexPath!
            break
        case .Update:
            print("Update(\(type.rawValue)) an item.")
            updatedIndexPaths.append(indexPath!)
            break
        }
    }
}