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
    var animateFallingPin : Bool = true
    
    var mapViewIF : MapViewInterface!
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mapView.delegate   = self
        self.mapViewIF = MapViewInterface(withMapView: self.mapView)
        self.mapViewIF.loadPersistedMapLocation()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("current map coordinate region: \(self.mapView.region)")
        print("hard recentering for testing purposes.")
        self.mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0))
    }

    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("mapView didSelectAnnotationView")
        self.performSegueWithIdentifier("showPhotoAlbum", sender: self)
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
            self.mapViewIF.lastPinSetToMap = nil
            //TODO: start prefetching of photos here!
            break
        case .Cancelled:
            print("state canceled")
            break
        case .Changed:
            print("state: changed")
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