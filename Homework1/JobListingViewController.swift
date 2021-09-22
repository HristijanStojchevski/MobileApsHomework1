//
//  JobListingViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/30/21.
//
//  Gets a list of posted jobs ordering first by distance ex: 2km then alphabetically
//  Distance formula: job.long - userPosition[1]
//  Distance = 6371*ACOS(COS(RAD(90 - Lat1)) * COS(RAD(90 - Lat2)) + SIN(RAD(90-Lat1))*SIN(RAD(90 - Lat2))*COS(RAD(Long1 - Long2)))  - This is in kilometers
//  Google maps long and lat are degrees
//  radiansLat = PI * Lat / 180

import UIKit
import SPPermissions
import CoreLocation
import Firebase

private let jobCellID = "AllJobsID"
private let earthOrbitalCircleRadius: Double = 6371
class JobListingViewController: UIViewController {
    
    let permissionsManager = SPPermissions.list([.locationWhenInUse])
    var locationManager = CLLocationManager()
    
    var userPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 41.048703, longitude: 21.336802){
        didSet {
            DispatchQueue.main.async {
                var nearJobs: [Job] = []
                self.jobs.removeAll()
                self.sectionNames.removeAll()
                self.firebaseJobs.forEach { (job) in
                    if !self.sectionNames.contains(job.category){
                        self.sectionNames.append(job.category)
                    }
                    // if maps api is not working use this aerial distance
                    
                    let alpha = 90 - self.userPosition.latitude
                    let betha = 90 - job.lat
                    let longitutes = self.userPosition.longitude - job.long
                    let radAlpha = alpha * Double.pi / 180
                    let radBetha = betha * Double.pi / 180
                    let radLongitudes = longitutes * Double.pi / 180
                    let acosineExpr = (cos(radAlpha) * cos(radBetha)) + (sin(radAlpha) * sin(radBetha) * cos(radLongitudes))
                    let distance = earthOrbitalCircleRadius * acos(acosineExpr)
                    let tempJob = job
                    tempJob.distance = round(distance * 100) / 100
                    if distance <= 5{
                        tempJob.category = "NEARBY"
                        nearJobs.append(tempJob)
                    } else {
                        self.jobs.append(tempJob)
                    }
                }
                
                nearJobs.sort { (job1, job2) -> Bool in
                    return job1.distance < job2.distance
                }
                self.jobs = nearJobs + self.jobs
                self.sectionNames.sort { (sec1, sec2) -> Bool in
                    return sec1 < sec2
                }
                self.sectionNames.insert("NEARBY", at: 0)
                if !self.jobs.contains(where: { (job) -> Bool in
                    return job.category == "NEARBY"
                }) {
                    self.jobs.insert(Job(name: "No nearby jobs", category: "NEARBY", lat: 0, long: 0, details: "In radius of 1km there are no jobs offered", distance: 0, finished: false), at: 0)
                }
                self.jobTableView.reloadData()
            }
        }
    }
    
    var jobs: [Job] = []
//    let firebaseJobs = [ Job(name: "Mow the grass", category: "Gardening", lat: 41.043341, long: 21.340759, details: "Mow the grass in the backyard", distance: 0),
//        Job(name: "Repainting", category: "Construction", lat: 41.0, long: 22.34, details: "My walls need some love after a couple of years", distance: 0),
//        Job(name: "Repainting", category: "Construction", lat: 51.5075944, long: -0.1126435, details: "We are smokers", distance: 0),
//        Job(name: "Change falt tire", category: "Repairs", lat: 51.5069031, long: -0.1103546, details: "Stuck on the road with a flat tire. Too old to change it", distance: 0),
//        Job(name: "Electricity went down", category: "Repairs", lat: 25, long: 30, details: "I don't know what happened but I am left out with zero electricity", distance: 0)
//    ]
    var firebaseJobs: [Job] = []
    var sectionNames: [String] = []
    
    @IBOutlet weak var jobTableView: UITableView!
    var locationAlwaysAlert = false
    
    let firebase = FirebaseService()
    var loadDataFromService = true
    override func viewDidLoad() {
        super.viewDidLoad()
        jobTableView.delegate = self
        jobTableView.dataSource = self
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
        loadDataFromService = false
        permissionsManager.title = "Permissions"
        permissionsManager.headerText = "Please allow all of this permissions so the app can work properly"
        permissionsManager.footerText = "When you allow these we hope you will have fun time using our app"
        // Jobs inside 2km
        locationAlwaysAlert = true
        FirebaseService.firebaseService.postedJobs.removeAll()
        firebaseJobs.removeAll()
        FirebaseService.firebaseService.getAllPostedJobs { (job) -> (Void) in
            self.firebaseJobs.append(job)
        } // Might be more needed now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.checkLocationAuthorization()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if loadDataFromService {
            firebaseJobs = FirebaseService.firebaseService.postedJobs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkLocationAuthorization()
            }
        }
        else {
            loadDataFromService = true
        }
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
        print("Always pop up func")
    }
    
    private func checkLocationAuthorization(){
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            if locationAlwaysAlert{
                askForLocationAlways()
                locationAlwaysAlert = false
            }
            determineUserLocation()
            break
        case .authorizedAlways:
            print("Authorized always")
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
            print("Ask to enable")
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
            // update job list
            userPosition = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 51.5075943, longitude: -0.1126488)
        }
        else {
            // tell the user to enable location services
            let alert = UIAlertController(title: "Location services are disabled!", message: "Please turn on location in order for the app to work properly", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                SPPermissionsOpener.openSettings()
            }))
            alert.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            print("Ask to enable")
        }
    }
}

extension JobListingViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionNames[section]
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionNames.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionName = sectionNames[section]
        return jobs.filter { (job) -> Bool in
            return job.category == sectionName
        }.count
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .gray
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionName = sectionNames[indexPath.section]
        let cell = jobTableView?.dequeueReusableCell(withIdentifier: jobCellID, for: indexPath) as! JobListTableViewCell
        let job = jobs.filter { (job) -> Bool in
            return job.category == sectionName
        }[indexPath.row]
        cell.jobName.text = job.name
        cell.jobDescr.text = job.details
        if job.distance < 1 {
            cell.jobDistance.text = "\(job.distance * 1000)m"
        }
        else {
            cell.jobDistance.text = String(format: "%.2fkm", job.distance)
        }
        //Init top border
        let topBorder = CAShapeLayer()
        let topPath = UIBezierPath()
        topPath.move(to: CGPoint(x: 0, y: 0))
        topPath.addLine(to: CGPoint(x: cell.frame.width, y: 0))
        topBorder.path = topPath.cgPath
        topBorder.strokeColor = UIColor.gray.cgColor
        topBorder.lineWidth = 1.0
//        topBorder.fillColor = UIColor.gray.cgColor

        cell.layer.addSublayer(topBorder)
        //Init bottom border
        let bottomBorder = CAShapeLayer()
        let bottomPath = UIBezierPath()
        bottomPath.move(to: CGPoint(x: 0, y: self.view.frame.height / 10))
        bottomPath.addLine(to: CGPoint(x: cell.frame.width, y: self.view.frame.height / 10))
        bottomBorder.path = bottomPath.cgPath
        bottomBorder.strokeColor = UIColor.gray.cgColor
        bottomBorder.lineWidth = 1.0
//        topBorder.fillColor = UIColor.gray.cgColor

        cell.layer.addSublayer(bottomBorder)
        return cell
     }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height / 10
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "NewJobViewController") as! NewJobViewController
        let sectionName = sectionNames[indexPath.section]
        let job = jobs.filter({ (helperJob) -> Bool in
                return helperJob.category == sectionName
            })[indexPath.row]
        vc.jobName = job.name
        vc.jobDetails = job.details
        vc.helperSelection = true
        vc.job = job
        vc.jobRef = job.jobRef
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension JobListingViewController: SPPermissionsDelegate{
    func didDenied(permission: SPPermission) {
        // Make an allert and tell him the only way he will have a fully funcional app if he goes to settings and changes the authorized permissions for this app
        _ = deniedData(for: permission)
    }
    func deniedData(for permission: SPPermission) -> SPPermissionDeniedAlertData? {
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

extension JobListingViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //
        checkLocationAuthorization()
    }
        
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // check for location authorization and if disabled ask to enable
        locationAlwaysAlert = true
        checkLocationAuthorization()
    }
}

extension JobListingViewController: NewJobDelegate {
    func saveChanges(job: Job) {
        print("Save changes")
    }
    
    func enrollJob(job: Job) {
        print("Delegate function called at JobListing")
//        FirebaseService.firebaseService.postedJobs.remove(at: FirebaseService.firebaseService.postedJobs.firstIndex(of: job)!)
//        FirebaseService.firebaseService.enrolledJobs.append(job)
//        firebaseJobs.remove(at: firebaseJobs.firstIndex(of: job)!)
//        jobs.remove(at: jobs.firstIndex(of: job)!)
//        self.jobTableView.reloadData()
    }
    
    func deleteJob(job: Job) {
        print("JobDeleted")
    }
    func cancelJob(job: Job) {
        print("Job canceled")
    }
    
}

