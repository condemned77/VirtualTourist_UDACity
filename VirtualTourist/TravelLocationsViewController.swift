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
    
    /*Here, the method configures multiple view elements.
    1. mapView, settings its delegate, instantiating a MapViewInterface, which 
    is supposed to provided easier controll mechanisms when the mapView is changed.
    2. load the previously presisted map location, i.e. recenter the map view on a
    previously chosen location, not just the initial location.
    3. load all previously persisted MKPointAnnotations to the map view.
    */
    override func viewDidLoad() {
        print("TavelLocationsViewController viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.bringSubviewToFront(toolbar)
        view.bringSubviewToFront(deleteButton)
        self.mapView.delegate   = self
        self.mapViewIF = MapViewInterface(withMapView: self.mapView)
        self.mapViewIF.loadPersistedMapLocation()
        restoreMapContent()
    }
    
    
    /*The method accesses the core data stack an requests all Pin instances that have
    previously been persisted. Then the method call the addPinsToMap method.*/
    func restoreMapContent() {
        let fetchReq = NSFetchRequest(entityName: "Pin")
        var pins : [Pin]
        do {
            pins = try sharedContext.executeFetchRequest(fetchReq) as! [Pin]
            print("\(pins.count) pins loaded")
            addPinsToMap(pins)
        } catch let error {
            print("error requesting pins from Core Data: \(error)")
        }
    }
    
    /*Adding the passed in pin to map after app start. In order to do so,
    the coordinates of a Pin instances are passed used when calling the method addPinToMap().
    Then, the pin instance and it's associated annotation on the map are stored in a instance variable
    collection(dictionary) called pins.*/
    func addPinsToMap(pins : [Pin]) {
        for pin in pins {
            print("loading pin: \(pin) to map")
            self.animateFallingPin = false
            let addedPointAnnotation = mapViewIF.addPinToMap(forCoordinate: pin.coordinates)
            self.pins[addedPointAnnotation] = pin
        }
    }
    
    /*This method has been implemented for testing purposes, in order to 'hard center' the mapView to the 
    coordinates 0.0 / 0,0.*/
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("current map coordinate region: \(self.mapView.region)")
        print("hard recentering for testing purposes.")
        self.mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0))
    }

    /*This method deletes all data that is associated with the annotationView instance
    that is passed into this method.
    The data associated is a pin instance and mulitple photo instances.
    First the MKAnnotationView instance is removed from the mapView.
    Secondly, the associated Pin instance is removed from the pins collection instance variable.
    Thirdly, the Pin instance is delete from the core data context.
    */
    func deletePin(andAnnotation annotationView : MKAnnotationView) {
        //find associated pin instance
        for (pointAnnotation, pin) in pins {
            print(pointAnnotation)
            if pointAnnotation == (annotationView.annotation as! MKPointAnnotation){
                //delete pin instance and annotation
                mapView.removeAnnotation(pointAnnotation)
                pins.removeValueForKey(pointAnnotation)
                sharedContext.deleteObject(pin)
                break
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    
    //MARK: MapView Callbacks
    
    /*This method is called if a user has clicked on a map AnnotationView, which is
    a Pin in this app. Clicking on a pin can have two causes:
    1. a user wants to see photos that are associated with this pin.
    2. a user wants to delete the pin.
    
    In 1., a new view controller is presented, where the desired photos are shown.
    In 2., the pin that is clicked is removed from the map, while the data structure
    that is associated to the pin, i.e. the Pin instance and mulitple Photo instances
    are deleted.
    */
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard deleteButtonVisible == false else {deletePin(andAnnotation: view); return}
        
        print("[TavelLocationsViewController mapView didSelectAnnotationView]")
        mapView.deselectAnnotation(view.annotation! , animated: true)
        let photoAlbumVC = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        if let viewAnnotation = view.annotation {
            if viewAnnotation.isKindOfClass(MKPointAnnotation) {
                let pointAnnotation = view.annotation! as! MKPointAnnotation
                let pin = self.pins[pointAnnotation]
                print("Pin has \(pin!.photos.count) photos.")
                
                photoAlbumVC.pin = pin!
                photoAlbumVC.mapViewRegion = mapView.region
                self.presentViewController(photoAlbumVC, animated: true, completion: nil)
                
            } else {
                print("MKPointAnnotation not unwrapped from MKAnnotationView, refusing to show PhotoAlbum")
            }
        }
    }
    
    
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
    
    /*Callback method of the MKMapViewDelegate protocol, is called if a new pin has been
    added to the map. If the pin drop should be animated, an animation is executed on the
    view of the Pin (type: MKAnnotationView). This animation looks as if the pin is falling
    onto the map. The instance variable animateFalling pin is set to true, if a long press
    is detected on the mapview.*/
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        print("mapView: didAddAnnotationViews: called. views: \(views.count)")
        if animateFallingPin == false {return}
        for annView : MKAnnotationView in views {
            let endFrame : CGRect  = annView.frame;
            annView.frame = CGRectOffset(endFrame, 0, -500);
            UIView.animateWithDuration(0.5, animations: {
                annView.frame = endFrame
            })
        }
    }
    
    
    /*Callback method of the Long Press Gesture Recognizer, set in the Main.storyboard. 
    If a long press is detected, a pin is supposed to fall onto the map.
    Also the pin is able to move over the map, as long as the press is held.*/
    @IBAction func longPressOnMapViewDetected(sender: UILongPressGestureRecognizer) {
        let touchLocation = sender.locationInView(self.mapView)
        let locationCoordinate : CLLocationCoordinate2D = self.mapView.convertPoint(touchLocation, toCoordinateFromView: self.mapView)
        switch sender.state {
        case .Began:
            print("State began")
            animateFallingPin = true
            mapViewIF.addPinToMap(forCoordinate: locationCoordinate)
            mapViewIF.storeCurrentMapPosition()
            break;
        case .Ended:
            print("State ended")
            let pin = Pin(withCoordiantes: locationCoordinate, andContext: sharedContext)
            pins[self.mapViewIF.lastPinSetToMap!] = pin
            mapViewIF.lastPinSetToMap = nil
            CoreDataStackManager.sharedInstance().saveContext()
            break
        case .Cancelled:
            print("state canceled")
            break
        case .Changed:
            print("state: changed")
            animateFallingPin = false
            mapViewIF.movePin(locationCoordinate)
            break
        case .Failed:
            print("state: failed")
            break
        case .Possible:
            print("state: possible")
            break
        }
    }
    
    /*Callback for pressing the edit button on the top right corner.
    Toggling  the button text does lead to issue in the following animation.*/
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        self.togglePinDeleteButton()
//       toggleEditButtonText()
    }
    
    /*Toggling the button text currently lead to an issue where the moveing mapview
    is moving to the bottom of the screen and relocating itself in its original position,
    instead of moving towards the bottom.*/
    func toggleEditButtonText() {
        if editButton.title == "Edit" {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    /*This method displays the delete button below the map. It does so by sliding a container view
    (which holds the button + the mapview itself) a certain offset to the top of the screen. This
    offset is equal to the height of the delete button. 
    Caution, the delete button is just a sign pressing it does nothing.*/
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
    
    /*Each time the user moves his fingers on the device screen, this method is called.
    Since in this app, the user moves the map, the map's location is stored each time
    the method is called. One could argue that touchesEnded would be a better callback
    method to use, however, the touchesEnded method was called very unreliably. Thus, sometimes
    the map location wasn't stored.*/
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesMoved touches: \(touches) withEvent \(event)")
        self.mapViewIF.storeCurrentMapPosition()
    }
    
    /*This callback method is invoked when a user touch did end. However, it's called very unreliably, so
    in order to persist the current map location, the method touchesMoved is used.*/
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesEnded touches:\(touches) with event: \(event)")
    }
}