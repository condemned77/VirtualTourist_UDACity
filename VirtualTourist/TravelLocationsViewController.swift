//
//  ViewController.swift
//  VirtualTourist
//
//  Created by M on 24/01/16.
//
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var lastPinSetToMap : MKAnnotation?
    var animateFallingPin : Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController: touchesBegan with event: \(event)")
    }
}

