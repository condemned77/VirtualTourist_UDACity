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

class TravelLocationsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    
    var mapViewIF : MapViewInterface!
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mapViewIF = MapViewInterface(withMapView: self.mapView)
        self.mapViewIF.loadPersistedMapLocation()
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
            self.mapViewIF.addPinToMap(forCoordinate: locationCoordinate, withFallAnimation: true)
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
        print("TravelLocationViewController: touchesBegan with event: \(event)")
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesMoved touches: \(touches) withEvent \(event)")
        self.mapViewIF.storeCurrentMapPosition()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TravelLocationViewController touchesEnded touches:\(touches) with event: \(event)")
    }
}