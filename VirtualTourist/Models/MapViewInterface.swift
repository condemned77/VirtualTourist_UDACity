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

class MapViewInterface : NSObject {
    var lastPinSetToMap : MKPointAnnotation?

    lazy var sharedContext = { CoreDataStackManager.sharedInstance().managedObjectContext}()
    weak var mapView : MKMapView!
    var currentMapLocation : MapLocation!

    
    init(withMapView mapView : MKMapView) {
        super.init()
        self.mapView            = mapView
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
        
        CoreDataStackManager.sharedInstance().saveContext()
    }


    //MARK: Manipulate map
    func addPinToMap(forCoordinate coordinate : CLLocationCoordinate2D) -> MKPointAnnotation {
        print("Add pin to: \(coordinate)")
        let annotation = MKPointAnnotation()
        annotation.title = "dropped pin"
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
        self.lastPinSetToMap = annotation
        return annotation
    }

    
    func movePin(toCoordinate : CLLocationCoordinate2D) {
        self.removeLastPinOnMap()
        self.addPinToMap(forCoordinate: toCoordinate)
    }
    
    func removeLastPinOnMap() {
        if let lastPin = self.lastPinSetToMap {
            self.mapView.removeAnnotation(lastPin)
        }
    }
}