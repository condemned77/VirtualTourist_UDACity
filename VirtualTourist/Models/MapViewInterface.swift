//
//  MapViewInterface.swift
//  VirtualTourist
//
//  Created by M on 31/01/16.
//
//

import Foundation
import MapKit
import CoreData

class MapViewInterface : NSObject, MKMapViewDelegate {
    var lastPinSetToMap : MKAnnotation?
    var animateFallingPin : Bool = true
    lazy var sharedContext = { CoreDataStackManager.sharedInstance().managedObjectContext}()
    weak var mapView : MKMapView!
    var currentMapLocation : MapLocation!
    
    init(withMapView mapView : MKMapView) {
        super.init()
        self.mapView            = mapView
        self.mapView.delegate   = self
    }
    
    func centerMapToCurrentLocation() {
        print("current location: \(self.mapView.region)")
        print("Centering to: \(self.currentMapLocation.mapRegion)")
        self.mapView.region = self.currentMapLocation.mapRegion
    }
    
    
    func loadPersistedMapLocation() {
        let req : NSFetchRequest = NSFetchRequest(entityName: "MapLocation")
        do {
            if let locations : [MapLocation] = try sharedContext.executeFetchRequest(req) as? [MapLocation] {
                if locations.count == 1 {
                    print("one location found: \(locations)")
                    self.currentMapLocation = locations[0]
                } else if locations.count > 1 {
                    print("unexpected map location count > 1: \(locations.count)")
                    print(locations)
                } else {
                    print("No previous location stored. Locations: \(locations.count)")
                }
            }
        } catch let error {
            print("error while fetching map location \(error)")
            self.currentMapLocation = nil
        }
        if self.currentMapLocation != nil {
            self.centerMapToCurrentLocation()
        }
    }
    
    func storeCurrentMapPosition() {
        let locationCoordinateRegion : MKCoordinateRegion = self.mapView.region

        if self.currentMapLocation == nil {
            self.currentMapLocation = MapLocation(coordinateRegion: locationCoordinateRegion, andContext: sharedContext)
        } else {
            self.currentMapLocation.mapRegion = locationCoordinateRegion
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


    //MARK: Manipulate map
    func addPinToMap(forCoordinate coordinate : CLLocationCoordinate2D, withFallAnimation animation : Bool) {
        print("Add pin to: \(coordinate)")
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
}