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

    @IBOutlet weak var mapView: MKMapView!
    
    var lastPinSetToMap : MKAnnotation?
    var animateFallingPin : Bool = true
    var currentMapLocation : MapLocation?
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let req : NSFetchRequest = NSFetchRequest(entityName: "MapLocation")
        do {
            let locations : [MapLocation]? = try sharedContext.executeFetchRequest(req) as! [MapLocation]
            if locations?.count == 1 {
                print("one location found: \(locations)")
                self.currentMapLocation = locations![0]
            } else if locations?.count > 1 {
                print("unexpected map location count > 1: \(locations?.count)")
                print(locations)
            } else {
                print("No previous location stored. Locations: \(locations?.count)")
            }
            
        } catch let error {
            print("error while fetching map location \(error)")
            self.currentMapLocation = nil
        }
        if self.currentMapLocation != nil {
            self.centerMapToCurrentLocation()
        }
    }

    
    func centerMapToCurrentLocation() {
        self.mapView.region = (self.currentMapLocation?.mapRegion)!
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("current map coordinate region: \(self.mapView.region)")
        print("hard recentering")
        self.mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0))
    }

    
    @IBAction func longPressOnMapViewDetected(sender: UILongPressGestureRecognizer) {
        let touchLocation = sender.locationInView(self.mapView)
        let locationCoordinate : CLLocationCoordinate2D = self.mapView.convertPoint(touchLocation, toCoordinateFromView: self.mapView)
        switch sender.state {
        case .Began:
            print("State began")
            addPinToMap(forCoordinate: locationCoordinate, withFallAnimation: true)
            break;
        case .Ended:
            print("State ended")
            self.lastPinSetToMap = nil
            //TODO: start prefetching of photos here!
            break
        case .Cancelled:
            print("state canceled")
            break
        case .Changed:
            print("state: changed")
            self.movePin(locationCoordinate)
            break
        case .Failed:
            print("state: failed")
            break
        case .Possible:
            print("state: possible")
            break
        }

    }
    func addPinToMap(forCoordinate coordinate : CLLocationCoordinate2D, withFallAnimation animation : Bool) {
        print("Add pin detected")
        self.animateFallingPin = animation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
        self.lastPinSetToMap = annotation
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
    
    func movePin(toCoordinate : CLLocationCoordinate2D) {
        self.removeLastPinOnMap()
        self.addPinToMap(forCoordinate: toCoordinate, withFallAnimation: false)
    }
    
    func removeLastPinOnMap() {
        if let lastPin = self.lastPinSetToMap {
            self.mapView.removeAnnotation(lastPin)
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
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    func storeMapPosition(locationCoordinateRegion : MKCoordinateRegion) {
        if self.currentMapLocation == nil {
            self.currentMapLocation = MapLocation(coordinateRegion: locationCoordinateRegion, andContext: sharedContext)
        } else {
            self.currentMapLocation!.mapRegion = locationCoordinateRegion
        }
        
        if sharedContext.hasChanges {
            do {
                try sharedContext.save()
                print("context saved with coordinateRegion: \(locationCoordinateRegion)")
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController: touchesBegan with event: \(event)")
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesMoved touches: \(touches) withEvent \(event)")
        let coordinateRegion : MKCoordinateRegion = self.mapView.region
        storeMapPosition(coordinateRegion)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesEnded touches:\(touches) with event: \(event)")
    }
}