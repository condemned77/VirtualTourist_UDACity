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
/*This class is supposed to provide an easy
interface to mapview functionality for the TravelLocationsViewController.*/
class MapViewInterface : NSObject {
    var lastPinSetToMap : MKPointAnnotation?

    lazy var sharedContext = { CoreDataStackManager.sharedInstance().managedObjectContext}()
    weak var mapView : MKMapView!
    var currentMapLocation : MapLocation!

    
    init(withMapView mapView : MKMapView) {
        super.init()
        self.mapView            = mapView
    }
    
    /*By calling this method, the location stored in the instance variable currentMapLocation
    is assigned to the mapView instance's region. Hence, the current mapview is focused
    on this new location.*/
    func centerMapToCurrentLocation() {
        print("current location: \(self.mapView.region)")
        print("Centering to: \(self.currentMapLocation.mapRegion)")
        self.mapView.region = self.currentMapLocation.mapRegion
    }
    
    
    /*This method loads the (possiblity) presisted map location on from core data
    and stores it in the instance variable currentMapLocation.
    Since there should be only once map location, in case multiple locations are
    loaded, the method loads neither and prints a corresponding message to the console.*/
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
    
    
    /*Convenience method for persisting the current map location to core data.*/
    func storeCurrentMapPosition() {
        let locationCoordinateRegion : MKCoordinateRegion = self.mapView.region

        //if no map location loaded, try loading it from core data
        if currentMapLocation == nil {
            loadPersistedMapLocation()
            //if map location still not avialable, create a new one.
            if currentMapLocation == nil {
                currentMapLocation = MapLocation(coordinateRegion: locationCoordinateRegion, andContext: sharedContext)
            }
        } else {
            currentMapLocation.mapRegion = locationCoordinateRegion
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
    }


    //MARK: Manipulate map
    /*This method is used for adding a pin to the mapview. For this, an MKPointAnnotation instance
    is created, configured, and added to the map. The last pin that has been added to the map is also
    stored in the instance variable lastPinSetToMap, since this is relevant when a pin is moved 
    along the map.*/
    func addPinToMap(forCoordinate coordinate : CLLocationCoordinate2D) -> MKPointAnnotation {
        print("Add pin to: \(coordinate)")
        let annotation = MKPointAnnotation()
        annotation.title = "dropped pin"
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        lastPinSetToMap = annotation
        return annotation
    }

    
    /*This method allows to create the illusion that a pin can be moved along the map.
    When the user dropped a pin to the map and holds his touch, the pin can be 
    dragged/moved along the map and will be finally placed when the finger is removed.
    This functionality is created, by removing the last pin that has been set to the map,
    and add a new one to the new location where the user has moved his finger to.*/
    func movePin(toCoordinate : CLLocationCoordinate2D) {
        self.removeLastPinOnMap()
        self.addPinToMap(forCoordinate: toCoordinate)
    }
    
    
    /*This method removes the pin that has been added to the map lastly.*/
    func removeLastPinOnMap() {
        if let lastPin = self.lastPinSetToMap {
            self.mapView.removeAnnotation(lastPin)
        }
    }
}