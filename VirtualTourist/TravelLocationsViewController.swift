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
    var longPressGestureRecogniser : UILongPressGestureRecognizer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.longPressGestureRecogniser = UILongPressGestureRecognizer(target: self, action: "addNewPinToMap")
        longPressGestureRecogniser.minimumPressDuration = 2
//        longPressGestureRecogniser.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(longPressGestureRecogniser)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func addNewPinToMap() {
        print("Add pin detected")
        switch self.longPressGestureRecogniser.state {
        case .Began:
            print("State began")
            break;
        case .Ended:
            print("State ended")
            break
        case .Cancelled:
            print("state canceled")
            break
        case .Changed:
            print("state: changed")
            break
        case .Failed:
            print("state: failed")
            break
        case .Possible:
            print("state: possible")
            break
        }
//        self.mapView.p
//        self.mapView.addAnnotation(MKPlacemark(placemark: <#T##CLPlacemark#>))
    }
    /*Callback method of the MKMapViewDelegate protocol.
    Here, the visual appearence of the map pins is set.*/
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
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

