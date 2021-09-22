//
//  MapViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 6/12/21.
//

import UIKit
import MapKit
import SPPermissions
import CoreLocation
import Firebase
class CustomPin: NSObject, MKAnnotation{
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String = "") {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let permissionsManager = SPPermissions.list([.locationWhenInUse])
    var locationManager = CLLocationManager()
    var locationAlwaysAlert = false
    
//    let firebaseJobs = [ Job(name: "Mow the grass", category: "Gardening", lat: 41.043341, long: 21.340759, details: "Mow the grass in the backyard", distance: 0),
//        Job(name: "Repainting", category: "Construction", lat: 41.0, long: 22.34, details: "My walls need some love after a couple of years", distance: 0),
//        Job(name: "Repainting", category: "Construction", lat: 51.5075944, long: -0.1126435, details: "We are smokers", distance: 0),
//        Job(name: "Change falt tire", category: "Repairs", lat: 51.5069031, long: -0.1103546, details: "Stuck on the road with a flat tire. Too old to change it", distance: 0),
//        Job(name: "Electricity went down", category: "Repairs", lat: 25, long: 30, details: "I don't know what happened but I am left out with zero electricity", distance: 0)
//    ]
    var firebaseJobs: [Job] = []
    var loadDataFromDefaults = true
    override func viewDidLoad() {
        super.viewDidLoad()
        // NotificationCenter.addObserver(   ) // Notification  Method... I register this and catch remote notification
        
        // Do any additional setup after loading the view.
        self.mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
        
        permissionsManager.title = "Permissions"
        permissionsManager.headerText = "Please allow all of this permissions so the app can work properly"
        permissionsManager.footerText = "When you allow these we hope you will have fun time using our app"
        // App logic
        locationAlwaysAlert = true
        loadDataFromDefaults = false
        //fetch Jobs
        firebaseJobs.removeAll()
        FirebaseService.firebaseService.postedJobs.removeAll()
        FirebaseService.firebaseService.getAllPostedJobs { (postedJob) -> (Void) in
            let coordinate = CLLocationCoordinate2D(latitude: postedJob.lat, longitude: postedJob.long)
            self.mapView.addAnnotation(CustomPin(coordinate: coordinate, title: postedJob.name))
            
//            self.firebaseJobs.append(postedJob)
            self.firebaseJobs = FirebaseService.firebaseService.postedJobs
            // Is the completion going to get called for every async task ??? !?!!
        }
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("MapView -> viewDidAppear")
        if loadDataFromDefaults {
            let updatedJobs = FirebaseService.firebaseService.postedJobs
            updateMapPins(updatedJobs: updatedJobs)
        }
        else {
            loadDataFromDefaults = true
        }
    }
    
    func updateMapPins(updatedJobs: [Job]) {
        let newJobs = updatedJobs.filter { (job) -> Bool in
            return !firebaseJobs.contains(where: { (jb) -> Bool in
                return job.name == jb.name && job.lat == jb.lat && job.long == jb.long
            })
        }
        let jobsToBeRemoved = firebaseJobs.filter { (job) -> Bool in
            return !updatedJobs.contains(where: { (jb) -> Bool in
                return job.name == jb.name && job.lat == jb.lat && job.long == jb.long
            })
        }
        firebaseJobs = updatedJobs
        for newJob in newJobs {
            let coordinate = CLLocationCoordinate2D(latitude: newJob.lat, longitude: newJob.long)
            self.mapView.addAnnotation(CustomPin(coordinate: coordinate, title: newJob.name))
        }
        let extraAnnotations = self.mapView.annotations.filter({ (annotationPin) -> Bool in
            return jobsToBeRemoved.contains { (job) -> Bool in
                return job.name == annotationPin.title && job.lat == annotationPin.coordinate.latitude && job.long == annotationPin.coordinate.longitude
            }
        })
        if extraAnnotations.count > 0 {
            self.mapView.removeAnnotations(extraAnnotations) // This might not work well.... If not iterate over the extra annotations and remove them one by one
        }
//        for oldJob in jobsToBeRemoved {
////            self.mapView.removeAnnotation(CustomPin(coordinate: coordinate, title: oldJob.name))
//            extraAnnotations.append(CustomPin(coordinate: coordinate, title: oldJob.name))
//        }
    }
    
    /*
    // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    private func askForLocationAlways(){
        let data = deniedData(for: .locationWhenInUse)
        let alert = UIAlertController(title: data?.alertOpenSettingsDeniedPermissionTitle, message: data?.alertOpenSettingsDeniedPermissionDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionButtonTitle, style: .default, handler: { action in
            SPPermissionsOpener.openSettings()
        }))
        alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionCancelTitle, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func checkLocationAuthorization(){
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            if locationAlwaysAlert{
                locationAlwaysAlert = false
                askForLocationAlways()
            }
            determineUserLocation()
            break
        case .authorizedAlways:
            determineUserLocation()
            break
        case .denied, .restricted:
            //tell him to go to settings
            let data = deniedData(for: .locationWhenInUse)
            
            let alert = UIAlertController(title: data?.alertOpenSettingsDeniedPermissionTitle, message: data?.alertOpenSettingsDeniedPermissionDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionButtonTitle, style: .default, handler: { action in
                SPPermissionsOpener.openSettings()
            }))
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionCancelTitle, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
        case .notDetermined:
            // ask for location permission
            permissionsManager.delegate = self
            permissionsManager.present(on: self)
            if SPPermission.locationWhenInUse.isAuthorized {
                determineUserLocation()
            }
            break
        @unknown default:
            break
        }
    }
    private func determineUserLocation(){
        if CLLocationManager.locationServicesEnabled() {
            mapView?.showsUserLocation = true
        }
        else {
            // tell the user to enable location services
            let alert = UIAlertController(title: "Location services are disabled!", message: "Please turn on location in order for the map to work properly", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                SPPermissionsOpener.openSettings()
            }))
            alert.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func setupCustomPinView(for annotation: CustomPin,on mapView: MKMapView) -> MKAnnotationView{
        let reuseIdentifier = NSStringFromClass(CustomPin.self)
        let flagAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        var flagAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation) as? MKPinAnnotationView
//        flagAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        if flagAnnotationView == nil {
//            print("nil for Marker")
//            flagAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        }
        flagAnnotationView.isEnabled = true
        flagAnnotationView.canShowCallout = true
        
        // Provide the annotation view's image.
//        let image = #imageLiteral(resourceName: "flag")
        let image = UIImage(systemName: "mappin.circle")
        flagAnnotationView.image = image
        
        // Provide the left image icon for the annotation.
//        flagAnnotationView.rightCalloutAccessoryView = UIImageView(image: UIImage(systemName: "mappin"))
//        flagAnnotationView.rightCalloutAccessoryView?.accessibilityIdentifier = "OpenLocation"
        
        // Offset the flag annotation so that the flag pole rests on the map coordinate.
        let offset = CGPoint(x: (image!.size.width) / 2, y: -(image!.size.height / 2) )
        flagAnnotationView.centerOffset = offset
        let openLocationBtn = UIButton(type: .detailDisclosure)
//        openLocationBtn.backgroundColor = .red
//        openLocationBtn.setTitle("GO", for: .normal)
        flagAnnotationView.rightCalloutAccessoryView = openLocationBtn
        flagAnnotationView.rightCalloutAccessoryView?.accessibilityIdentifier = "OpenJob"
        return flagAnnotationView
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        mapView.register(CustomPin.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(CustomPin.self))
//        for job in firebaseJobs {
//            let coordinate = CLLocationCoordinate2D(latitude: job.lat, longitude: job.long)
//            customPins.append(CustomPin(coordinate: coordinate, title: job.name))
//        }
//        mapView.addAnnotations(customPins)
        checkLocationAuthorization()
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if view.rightCalloutAccessoryView?.accessibilityIdentifier == "OpenJob" {
            if control.isTouchInside {
                let pin = view.annotation
                let job = firebaseJobs.first { (jb) -> Bool in
                    return jb.name == pin?.title && jb.lat == pin?.coordinate.latitude && jb.long == pin?.coordinate.longitude
                }
                let vc = storyboard?.instantiateViewController(identifier: "NewJobViewController") as! NewJobViewController
                vc.job = job
                vc.jobRef = job?.jobRef
                vc.helperSelection = true
                vc.delegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        guard !annotation.isKind(of: MKUserLocation.self) else {
                // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
                return nil
            }


        var annotationView: MKAnnotationView?
        
        if let annot = annotation as? CustomPin {
            annotationView = setupCustomPinView(for: annot, on: mapView)
        }


        return annotationView
    }
}

extension MapViewController: SPPermissionsDelegate{
    func didDenied(permission: SPPermission) {
        // Make an allert and tell him the only way he will have a fully funcional app if he goes to settings and changes the authorized permissions for this app
        _ = deniedData(for: permission)
    }
    func deniedData(for permission: SPPermission) -> SPPermissionDeniedAlertData? {
        print("Inside deniedData function")
        if permission == .locationWhenInUse{
            let data = SPPermissionDeniedAlertData()
            data.alertOpenSettingsDeniedPermissionTitle = "Permission for the usage of location services was denied"
            data.alertOpenSettingsDeniedPermissionDescription = "Please go to settings and enable location services at all times so we can notify you when there is a new job nearby :)"
            data.alertOpenSettingsDeniedPermissionButtonTitle = "Settings"
            data.alertOpenSettingsDeniedPermissionCancelTitle = "Cancel"
            return data
        }
        else {
                // If returned nil, alert will not show.
                return nil
            }
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        checkLocationAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // check for location authorization and if disabled ask to enable
        locationAlwaysAlert = true
        checkLocationAuthorization()
    }
}

extension MapViewController: NewJobDelegate {
    func saveChanges(job: Job) {
        print("Save changes")
    }
    
    func enrollJob(job: Job) {
        print("Delegate method called")
    }
    func cancelJob(job: Job) {
        print("Job canceled")
//        FirebaseService.firebaseService.enrolledJobs.remove(at: FirebaseService.firebaseService.enrolledJobs.firstIndex(of: job) ?? -1)
    }
    
    func deleteJob(job: Job) {
        print("Job deleted")
//        FirebaseService.firebaseService.finishedJobs.remove(at: FirebaseService.firebaseService.finishedJobs.firstIndex(of: job) ?? -1)
    }
    
}
