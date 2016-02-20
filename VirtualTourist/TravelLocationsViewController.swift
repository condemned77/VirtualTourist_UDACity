//
//  ViewController.swift
//  VirtualTourist
//
//  Created by M on 24/01/16.
//
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    var animateFallingPin : Bool = true
    var deleteButtonVisible : Bool = false
    
    var mapViewIF : MapViewInterface!
    var pins : [MKPointAnnotation : Pin] = [MKPointAnnotation : Pin]()
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet weak var containerView : UIView!
    @IBOutlet weak var deleteButton : UIButton!
    
    override func viewDidLoad() {
        print("TavelLocationsViewController viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.bringSubviewToFront(toolbar)
        view.bringSubviewToFront(deleteButton)
        self.mapView.delegate   = self
        self.mapViewIF = MapViewInterface(withMapView: self.mapView)
        self.mapViewIF.loadPersistedMapLocation()
        let fetchReq = NSFetchRequest(entityName: "Pin")
        var pins : [Pin]
        do {
            pins = try sharedContext.executeFetchRequest(fetchReq) as! [Pin]
            print("\(pins.count) pins loaded")
            self.loadPinsToMap(pins)
        } catch let error {
            print("error requesting pins from Core Data: \(error)")
        }
    }
    
    //loading persisted pin to map after app start.
    func loadPinsToMap(pins : [Pin]) {
        for pin in pins {
            print("loading pin: \(pin) to map")
            self.animateFallingPin = false
            let addedPointAnnotation = mapViewIF.addPinToMap(forCoordinate: pin.coordinates)
            self.pins[addedPointAnnotation] = pin
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("current map coordinate region: \(self.mapView.region)")
        print("hard recentering for testing purposes.")
        self.mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0))
    }

    
    func deletePin(andAnnotation annotationView : MKAnnotationView) {
        //find associated pin instance
        for (pointAnnotation, pin) in pins {
            print(pointAnnotation)
            if pointAnnotation == (annotationView.annotation as! MKPointAnnotation){
//                delete pin instance and annotation
                mapView.removeAnnotation(pointAnnotation)
                pins.removeValueForKey(pointAnnotation)
                sharedContext.deleteObject(pin)
                break
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard deleteButtonVisible == false else {
            deletePin(andAnnotation: view)
            return
        }
        
        print("[TavelLocationsViewController mapView didSelectAnnotationView]")
        mapView.deselectAnnotation(view.annotation! , animated: true)
        let photoAlbumVC = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        if let viewAnnotation = view.annotation {
            if viewAnnotation.isKindOfClass(MKPointAnnotation) {
                let pointAnnotation = view.annotation! as! MKPointAnnotation
                let pin = self.pins[pointAnnotation]
                print("Pin has \(pin!.photos.count) photos.")
                
                photoAlbumVC.pin = pin!
                photoAlbumVC.mapViewRegion = self.mapView.region
                self.presentViewController(photoAlbumVC, animated: true, completion: nil)

            } else {
                print("MKPointAnnotation not unwrapped from MKAnnotationView, refusing to show PhotoAlbum")
            }
        }
    }
    
    
    //MARK: MapView Callbacks
    /*Callback method of the MKMapViewDelegate protocol.
    Here, the visual appearence of the map pins is set.*/
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("mapView viewForAnnotation called")
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.canShowCallout = false
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        print("mapView: didAddAnnotationViews: called. views: \(views.count)")
        if self.animateFallingPin == false {return}
        for annView : MKAnnotationView in views {
            let endFrame : CGRect  = annView.frame;
            annView.frame = CGRectOffset(endFrame, 0, -500);
            UIView.animateWithDuration(0.5, animations: {
                annView.frame = endFrame
            })
        }
    }
    
    
    @IBAction func longPressOnMapViewDetected(sender: UILongPressGestureRecognizer) {
        let touchLocation = sender.locationInView(self.mapView)
        let locationCoordinate : CLLocationCoordinate2D = self.mapView.convertPoint(touchLocation, toCoordinateFromView: self.mapView)
        switch sender.state {
        case .Began:
            print("State began")
            self.animateFallingPin = true
            self.mapViewIF.addPinToMap(forCoordinate: locationCoordinate)
            break;
        case .Ended:
            print("State ended")
            let pin = Pin(withCoordiantes: locationCoordinate, andContext: sharedContext)
            self.pins[self.mapViewIF.lastPinSetToMap!] = pin
            self.mapViewIF.lastPinSetToMap = nil
            CoreDataStackManager.sharedInstance().saveContext()
            break
        case .Cancelled:
            print("state canceled")
            break
        case .Changed:
            print("state: changed")
            self.animateFallingPin = false
            self.mapViewIF.movePin(locationCoordinate)
            break
        case .Failed:
            print("state: failed")
            break
        case .Possible:
            print("state: possible")
            break
        }
    }
    

    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        self.togglePinDeleteButton()
//       toggleEditButtonText()
    }
    
    func toggleEditButtonText() {
        editButton.title = "Edit"
        editButton.title = "Done"
    }
    
    func togglePinDeleteButton() {
        var y_offset : CGFloat
        if deleteButtonVisible {
            y_offset = self.deleteButton.frame.height

        } else {
            y_offset = -self.deleteButton.frame.height
        }
        deleteButtonVisible = !deleteButtonVisible
        UIView.animateWithDuration(1, animations: {
            self.containerView.center = CGPoint(x: self.containerView.center.x, y: self.containerView.center.y + y_offset)
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        print("TravelLocationViewController: touchesBegan with event: \(event)")
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesMoved touches: \(touches) withEvent \(event)")
        self.mapViewIF.storeCurrentMapPosition()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesEnded touches:\(touches) with event: \(event)")
    }
}