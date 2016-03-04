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
    func newImageURLDownloaded(urlString : String, withPhotoID: String)
    func setPageAmountOfLastRequest(pages : Int, currentPage : Int)
    func errorWhileDownloading()
}

class FlickrAPI: NSObject {
    var imageData   : [String : String] = [String : String]()
    var longitude   : Double?
    var latitude    : Double?
    var delegate    : ImageURLDownloadedDelegate?
    
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

    /*Convenience method for converting assigned longitude and latitude into a CLLocationCoordinate2D instance.*/
    private func createCoordinates() -> CLLocationCoordinate2D {
        let coordinates : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: self.latitude!, longitude: self.longitude!)
        return coordinates
    }
    
    /*Conveniene method for spanning a so called bounding box over a certain location. This location is based on the coordinates
    (longitude and latitude) that are assigned to the Flickr sharedInstance. Basically by using a single coordinate, a whole
    area is created in order to enlarge the area to be searched for Flickr photos.*/
    private func bboxString() -> String{
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(self.longitude! - FlickrConstants.Flickr.SearchBBoxHalfWidth, FlickrConstants.Flickr.SearchLonRange.0)
        let bottom_left_lat = max(self.latitude! - FlickrConstants.Flickr.SearchBBoxHalfWidth, FlickrConstants.Flickr.SearchLatRange.0)
        let top_right_lon = min(self.longitude! + FlickrConstants.Flickr.SearchBBoxHalfHeight, FlickrConstants.Flickr.SearchLonRange.1)
        let top_right_lat = min(self.latitude! + FlickrConstants.Flickr.SearchBBoxHalfHeight, FlickrConstants.Flickr.SearchLatRange.1)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    
    /*Convenience method for searching photo images based on provided coordinates. The method also takes a delegate, that
    is notified each time a single image url has been parsed, i.e. is available.
    In order to query the FlickrAPI for photos, multiple parameter are setup in this method.
    - method: the first request parameter is called method which designates the functionality (provided by the flickr API) that the request is addressing.
    - APIKey: the APIKey identifies the origin that executes the call. This means, every request has to be done using such an APIKey. An origin can be an application.
    - BoundingBox: see method bboxString()
    - SafeSearch: use flickr censoring or not.
    - extras: this parameter accepts a few extra commands which allow for enriching the photo related data sets.
    E.g.: description, license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags, o_dims, views, media, path_alias, url_sq, url_t, url_s, url_q, url_m, url_n, url_z, url_c, url_l, url_o
    - format: determines the data format which the response should have. As far as knowledge goes, json and xml are most common.
    - nojsoncallback: The JSON is valid javascript, i.e. it describes a javascript object. Based on how the json response shall be processed, it’s possible to wrap the JSON response into a function, called callback which can be executed directly including the data of the JSON response. When this isn’t needed, the request parameter nojsoncallback=1 should be inserted. (From the flickr API description:
    If you just want the raw JSON, with no function wrapper, add the parameter nojsoncallback with a value of 1 to your request.)
    - SearchAccuracy: Recorded accuracy level of the location information. Current range is 1-16 : used is 6 for region accuracy.
    Additional information:
    - The parameter order is arbitrary.
    */
    func searchImagesByLatLon(forCoordinates coor : CLLocationCoordinate2D, updateMeForEachURL delegate : ImageURLDownloadedDelegate?, pageNumber: Int?, completionHandler : (([String : String], NSError?) -> Void)?) {
        print("searching photos for coordinates: \(coor)")
        self.photoCoordinates = coor
        self.delegate = delegate
        
       
        var methodParameters = [
            FlickrConstants.FlickrParameterKeys.Method: FlickrConstants.FlickrParameterValues.SearchMethod,
            FlickrConstants.FlickrParameterKeys.APIKey: FlickrConstants.FlickrParameterValues.APIKey,
            FlickrConstants.FlickrParameterKeys.BoundingBox: bboxString(),
            FlickrConstants.FlickrParameterKeys.SafeSearch: FlickrConstants.FlickrParameterValues.UseSafeSearch,
            FlickrConstants.FlickrParameterKeys.Extras: FlickrConstants.FlickrParameterValues.MediumURL,
            FlickrConstants.FlickrParameterKeys.Format: FlickrConstants.FlickrParameterValues.ResponseFormat,
            FlickrConstants.FlickrParameterKeys.NoJSONCallback: FlickrConstants.FlickrParameterValues.DisableJSONCallback,
            FlickrConstants.FlickrParameterKeys.SearchAccuracy: FlickrConstants.FlickrParameterValues.accuracyValue,
            FlickrConstants.FlickrParameterKeys.PerPage : FlickrConstants.FlickrParameterValues.perPageVirtualTourist
        ]
    
        if let pageNum = pageNumber {
            methodParameters[FlickrConstants.FlickrParameterKeys.Page] = String(pageNum)
        }

        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue) {
            print("This is run on the background queue")
            self.downloadImageData(withParameter: methodParameters, withCompletionHandler : completionHandler)
        }
    }

    /*This method starts downloading Flickr images basd on the parameter passed in. It handles various error scenarios
    and executes a completion handler after image urls have been downloaded and parsed.*/
    private func downloadImageData(withParameter methodParameters: [String:AnyObject], withCompletionHandler handler : (([String : String], NSError?) -> Void)?) {
        
        // create session and request
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
                self.delegate?.errorWhileDownloading()
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
            
            if let amountOfPages : Int = (photosDictionary[FlickrConstants.FlickrResponseKeys.Pages] as! Int){
                if let currentPageReturned : Int = (photosDictionary[FlickrConstants.FlickrResponseKeys.Page] as! Int) {
                    self.delegate!.setPageAmountOfLastRequest(amountOfPages, currentPage: currentPageReturned)
                }
            }

            if let photos = photosDictionary["photo"] as? [[String : AnyObject]] {
                for photo in photos {
//                    print("key: \(url["url_m"])")
                    let urlString   = photo["url_m"] as! String
                    let imageID     = photo["id"] as! String
                    self.delegate?.newImageURLDownloaded(urlString, withPhotoID: imageID)
                    self.imageData[imageID] = urlString
                }
                handler?(self.imageData, nil)
            }
        }
        
        // start the task!
        task.resume()
    }
    
    
    /*Convenience method for assembling a URL from passed in parameters.*/
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
    
    /*A FlickrAPI instance should only exist once.*/
    class func sharedInstance() -> FlickrAPI {
        struct Static {
            static let sharedInstance = FlickrAPI()
        }
        return Static.sharedInstance
    }
}