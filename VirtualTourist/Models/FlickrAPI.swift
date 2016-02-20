//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by M on 31/01/16.
//
//

import Foundation
import MapKit

protocol ImageURLDownloadedDelegate {
    func newImageURLDownloaded(urlString : String);
}

class FlickrAPI: NSObject {
    var imageURLs : [String] = [String]()
    var longitude : Double?
    var latitude : Double?
    var delegate : ImageURLDownloadedDelegate?
    
    var photoCoordinates : CLLocationCoordinate2D? {
        set (newCoordinates){
            self.longitude = newCoordinates!.longitude
            self.latitude = newCoordinates!.latitude
        }
        get {
            return self.createCoordinates()
        }
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }

    
    private func createCoordinates() -> CLLocationCoordinate2D {
        let coordinates : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: self.latitude!, longitude: self.longitude!)
        return coordinates
    }
    
    private func bboxString() -> String{
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(self.longitude! - FlickrConstants.Flickr.SearchBBoxHalfWidth, FlickrConstants.Flickr.SearchLonRange.0)
        let bottom_left_lat = max(self.latitude! - FlickrConstants.Flickr.SearchBBoxHalfWidth, FlickrConstants.Flickr.SearchLatRange.0)
        let top_right_lon = min(self.longitude! + FlickrConstants.Flickr.SearchBBoxHalfHeight, FlickrConstants.Flickr.SearchLonRange.1)
        let top_right_lat = min(self.latitude! + FlickrConstants.Flickr.SearchBBoxHalfHeight, FlickrConstants.Flickr.SearchLatRange.1)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    

    func searchImagesByLatLon(forCoordinates coor : CLLocationCoordinate2D, updateMeForEachURL delegate : ImageURLDownloadedDelegate?, completionHandler : (([String], NSError?) -> Void)?) {
        print("searching photos for coordinates: \(coor)")
        self.photoCoordinates = coor
        self.delegate = delegate
        let methodParameters = [
            FlickrConstants.FlickrParameterKeys.Method: FlickrConstants.FlickrParameterValues.SearchMethod,
            FlickrConstants.FlickrParameterKeys.APIKey: FlickrConstants.FlickrParameterValues.APIKey,
            FlickrConstants.FlickrParameterKeys.BoundingBox: bboxString(),
            FlickrConstants.FlickrParameterKeys.SafeSearch: FlickrConstants.FlickrParameterValues.UseSafeSearch,
            FlickrConstants.FlickrParameterKeys.Extras: FlickrConstants.FlickrParameterValues.MediumURL,
            FlickrConstants.FlickrParameterKeys.Format: FlickrConstants.FlickrParameterValues.ResponseFormat,
            FlickrConstants.FlickrParameterKeys.NoJSONCallback: FlickrConstants.FlickrParameterValues.DisableJSONCallback,
            FlickrConstants.FlickrParameterKeys.SearchAccuracy: FlickrConstants.FlickrParameterValues.accuracyValue
        ]
        dispatch_async(dispatch_get_main_queue()) {
            self.downloadImageData(withParameter: methodParameters, withCompletionHandler : completionHandler)
        }
    }

    private func downloadImageData(withParameter methodParameters: [String:AnyObject], withCompletionHandler handler : (([String], NSError?) -> Void)?) {
        
        // create session and request
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
//                performUIUpdatesOnMain {
//                    self.setUIEnabled(true)
//                    self.photoTitleLabel.text = "No photo returned. Try again."
//                    self.photoImageView.image = nil
//                }
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
//                print("parsed result: \(parsedResult)")
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrConstants.FlickrResponseKeys.Status] as? String where stat == FlickrConstants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[FlickrConstants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(FlickrConstants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
//            print("photoDictionary: \(photosDictionary)")
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let _ = photosDictionary[FlickrConstants.FlickrResponseKeys.Pages] as? Int else {
                displayError("Cannot find key '\(FlickrConstants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            if let photos = photosDictionary["photo"] as? [[String : AnyObject]] {
                for url in photos {
//                    print("key: \(url["url_m"])")
                    let urlString = url["url_m"] as! String
                    self.delegate?.newImageURLDownloaded(urlString)
                    self.imageURLs.append(urlString)
                }
                handler?(self.imageURLs, nil)
            }
        }
        
        // start the task!
        task.resume()
    }
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = FlickrConstants.Flickr.APIScheme
        components.host = FlickrConstants.Flickr.APIHost
        components.path = FlickrConstants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    class func sharedInstance() -> FlickrAPI {
        struct Static {
            static let sharedInstance = FlickrAPI()
        }
        return Static.sharedInstance
    }
}