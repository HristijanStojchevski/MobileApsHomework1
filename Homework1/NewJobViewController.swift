//
//  NewJobViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/29/21.
//

import UIKit
import SPPermissions
import AVFoundation
import CoreLocation
import UserNotifications
import Firebase

protocol NewJobDelegate {
    func enrollJob(job: Job)
    
    func deleteJob(job: Job)
    
    func cancelJob(job: Job)
    
    func saveChanges(job: Job)
}

class NewJobViewController: UIViewController, AVAudioRecorderDelegate{
    
    var delegate: NewJobDelegate?
    var job: Job?
    var jobName: String = ""
    var sectionName: String = ""
    var jobRef: DocumentReference?
    @IBOutlet weak var jobTitleLbl: UILabel!
    @IBOutlet weak var jobNameTxt: UITextField!
    @IBOutlet weak var jobDetailsTxtView: UITextView!
    @IBOutlet weak var imageDescription: UIImageView!
    var jobDetails: String = ""
    var newJob: Bool = false;
    var enrolledJob: Bool = false;
    var helperSelection: Bool = false;
    var helperFinished: Bool = false;
    var helperEnrolled: Bool = false;
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    
    @IBAction func playRecording(_ sender: Any) {
        do {
            if newJob || saveBtn.isEnabled {
            let filename = getDirectory().appendingPathComponent("audioDescription.m4a")
                
            audioPlayer = try AVAudioPlayer(contentsOf: filename)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            }
            else {
                // get filename and audio from firebase storage
//                let data = smth from firebase
//                audioPlayer = try AVAudioPlayer(data: <#T##Data#>)
                print("Firebase audio")
            }
        } catch {
            print("Probably no recording or problem while playing")
        }
    }
    let microphoneSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    
    @IBAction func startRecording(_ sender: Any) {
        // Check mic permissions
        if checkMicrophoneAuthorization(){
            print("MIc start recording")
            let filename = getDirectory().appendingPathComponent("audioDescription.m4a")
//            let filename = Bundle.main.path(forResource: "audioRec", ofType: "mp3")
            do {
                audioRecorder = try AVAudioRecorder(url: filename, settings: microphoneSettings)
                audioRecorder.delegate = self
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                
                // Change mic icon to filled while recording
//                recordBtn.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            } catch {
                print("Error while recording audio")
            }
        }
    }
    
    
    
    private func getDirectory() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDir = paths[0]
        return documentDir
    }
    @IBAction func endRecordingInside(_ sender: Any) {
        if audioRecorder != nil {
            print("End recording INSIDE!")
            audioRecorder.stop()
            audioRecorder = nil
            
        }
    }
    @IBAction func endRecordingOutside(_ sender: Any) {
        if audioRecorder != nil {
            print("End recording  OUTSIDE!")
            audioRecorder.stop()
            audioRecorder = nil
            
        }
    }
    
    
    @IBAction func openCamera(_ sender: Any) {
        if checkCameraAuth() && checkLocationAuthorization(){
            
            print("Camera btn pressed")
            takePhoto = true // AVFoundation method
            prepareCamera()
            
            // ImagePicker simple method
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    var userPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 41.048703, longitude: 21.336802)
    
    var takenPhoto: UIImage?
    var takePhoto = false
    var permissionsManager = SPPermissions.list([.camera, .microphone, .notification, .locationWhenInUse])
    
    var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer! = nil
    private let captureSession = AVCaptureSession()
    var previewLayer: CALayer!
    var captureDevice: AVCaptureDevice!
    
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var cameraBtn: UIButton!
    
    @IBAction func saveChanges(_ sender: Any) {
        // Also take audio of file system store it to Firebase and delete it locally
        if saveBtn.titleLabel?.text == "Delete" {
            deleteTapped()
        }
        else if saveBtn.titleLabel?.text == "Mark Finished" {
            finishedTapped()
        }
        else {
        print("Notify nearby helpers")
        let jobData = [ "description": jobDetailsTxtView.text ?? ""] as [String : Any] //  "audio", "image"
        FirebaseService.firebaseService.updateDocument(docRef: jobRef!, dataUpdate: jobData)
        job?.details = jobDetailsTxtView.text ?? ""
        self.delegate?.saveChanges(job: job!)
        self.dismiss(animated: true)
        }
    }
    @IBOutlet weak var saveBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        saveBtn.isEnabled = false
        saveBtn.isHidden = true
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
        
        permissionsManager.title = "Permissions"
        permissionsManager.headerText = "Please allow all of this permissions so the app can work properly"
        permissionsManager.footerText = "When you allow these we hope you will have fun time using our app"
        
        jobName = job?.name ?? ""
        if job?.category ?? "" != "" {
            sectionName = job?.category ?? ""
        }
        jobRef = job?.jobRef
        jobDetails = job?.details ?? ""
        
        if jobName == "" {
            jobTitleLbl.text = "New Job type"
            jobNameTxt.text = "Enter name"
            jobNameTxt.layer.borderWidth = 0.5
            jobNameTxt.layer.borderColor = UIColor.lightGray.cgColor
            jobNameTxt.layer.cornerRadius = 10
        }
        else {
            jobNameTxt.text = jobName
            jobNameTxt.isEnabled = false
        }
        jobDetailsTxtView.text = jobDetails // If there is a general descr in firebase add that
        jobDetailsTxtView.layer.borderWidth = 1
        jobDetailsTxtView.layer.borderColor = UIColor.lightGray.cgColor
        jobDetailsTxtView.layer.cornerRadius = 20
        
        if newJob {
            // If new job...
            let saveJob = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))

            navigationItem.rightBarButtonItems = [saveJob]
        }
        else if enrolledJob{
            // If enrolled then enable marking as Finished
            saveBtn.isHidden = false
            saveBtn.isEnabled = true
            if job!.finished {
                saveBtn.setTitle("Delete", for: .normal)
//                let deleteJob = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteTapped))
//
//                navigationItem.rightBarButtonItems = [deleteJob]
            } else {
                saveBtn.setTitle("Mark Finished", for: .normal)
//                let markFinished = UIBarButtonItem(title: "Mark Finished", style: .plain, target: self, action: #selector(finishedTapped))
//
//                navigationItem.rightBarButtonItems = [markFinished]
            }
            
            jobNameTxt.isEnabled = false
            jobDetailsTxtView.isUserInteractionEnabled = false
            cameraBtn.isHidden = true
            cameraBtn.isEnabled = false
            recordBtn.isHidden = true
            recordBtn.isEnabled = false
        }
        else if helperSelection{
            // If posted job enable Editing
            if jobName != "No nearby jobs" {
            let enrollJob = UIBarButtonItem(title: "Enroll", style: .plain, target: self, action: #selector(enrollTapped))

            navigationItem.rightBarButtonItems = [enrollJob]
            }
            jobNameTxt.isEnabled = false
            jobDetailsTxtView.isUserInteractionEnabled = false
            cameraBtn.isHidden = true
            cameraBtn.isEnabled = false
            recordBtn.isHidden = true
            recordBtn.isEnabled = false
        }
        else if helperFinished{
            // If posted job enable Editing
            let deleteJob = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteTapped))

            navigationItem.rightBarButtonItems = [deleteJob]
            jobNameTxt.isEnabled = false
            jobDetailsTxtView.isUserInteractionEnabled = false
            cameraBtn.isHidden = true
            cameraBtn.isEnabled = false
            recordBtn.isHidden = true
            recordBtn.isEnabled = false
        }
        else if helperEnrolled{
            // If posted job enable Editing
            let cancelJob = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))

            navigationItem.rightBarButtonItems = [cancelJob]
            jobNameTxt.isEnabled = false
            jobDetailsTxtView.isUserInteractionEnabled = false
            cameraBtn.isHidden = true
            cameraBtn.isEnabled = false
            recordBtn.isHidden = true
            recordBtn.isEnabled = false
        }
        else {
            // If posted job enable Editing
            saveBtn.isHidden = false
            saveBtn.isEnabled = true
        }
        notificationHanlder()
        
    }
    
    @objc func enrollTapped(){
        FirebaseService.firebaseService.getLoggedInUser { (userRef) in
            userRef.setData(["jobs": FieldValue.arrayUnion([self.jobRef!])], merge: true) // Possible ref not saved in defaults via JsonEncoder
            self.jobRef?.updateData(["enrolled": true, "helper": userRef])
            
            FirebaseService.firebaseService.postedJobs.remove(at: FirebaseService.firebaseService.postedJobs.firstIndex(of: self.job!) ?? -1)
            FirebaseService.firebaseService.enrolledJobs.append(self.job!)
//            self.delegate?.enrollJob(job: self.job!)
            
            self.navigationController?.popViewController(animated: true)
            print("Job enrolled")
            print("Notify elder")
        }
        // Take him to dash and refresh Map
    }
    @objc func deleteTapped(){
        FirebaseService.firebaseService.getLoggedInUser { (userRef) in
            userRef.setData(["jobs": FieldValue.arrayRemove([self.jobRef!])], merge: true)
            if userRef.parent.collectionID == "elders" {
                self.jobRef?.getDocument(completion: { (jb, err) in
                    if let err = err {
                        print(err)
                    } else {
                        let helperRef = jb?.get("helper") as? DocumentReference
                        helperRef?.setData(["jobs": FieldValue.arrayRemove([self.jobRef!])], merge: true)
                        self.jobRef?.delete()
                    }
                    
                })
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            self.delegate?.deleteJob(job: self.job!)
        }
    }
    @objc func cancelTapped(){
        FirebaseService.firebaseService.getLoggedInUser { (userRef) in
            self.jobRef?.getDocument(completion: { (docSnap, err) in
                if let err = err {
                    print("NewJobView cancel job ERROR - >", err)
                } else {
                    var jobData = docSnap?.data()
                    jobData?.removeValue(forKey: "helper")
                    jobData?.updateValue(false, forKey: "enrolled")
                    docSnap?.reference.setData(jobData!)
                    userRef.setData(["jobs": FieldValue.arrayRemove([self.jobRef!])], merge: true)
                }
            })
            self.delegate?.cancelJob(job: self.job!)
            self.navigationController?.popViewController(animated: true)
            print("Helper canceled the job")
            print("Notify elder")
        }
    }
    @objc func finishedTapped(){
        self.jobRef?.updateData(["finished": true])
//        let deleteJob = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteTapped))
//
//        navigationItem.rightBarButtonItems = [deleteJob]
        saveBtn.setTitle("Delete", for: .normal)
//        self.navigationController?.popViewController(animated: true)
        print("Job marked as finished")
        print("notify helper")
    }
    @objc func saveTapped(){
        // Check if everythin is filled
        print(" Save btn tapped ")
        if jobNameTxt.text != "" && jobNameTxt.text != "Enter name"{
            jobName = jobNameTxt.text ?? "Wrong name"
        let location = GeoPoint(latitude: userPosition.latitude, longitude: userPosition.longitude)
        let jobData = [ "title": jobName, "description": jobDetailsTxtView.text ?? "", "enrolled": false, "finished": false, "location": location ] as [String : Any]
        let newJobRef = FirebaseService.firebaseService.createJob(category: sectionName, jobData: jobData)
        if job != nil && FirebaseService.firebaseService.postedJobs.contains(job!) {
            FirebaseService.firebaseService.postedJobs.remove(at: FirebaseService.firebaseService.postedJobs.firstIndex(of: job!) ?? -1)
            job?.name = jobName
            job?.details = jobDetailsTxtView.text ?? ""
            job?.enrolled = false
            job?.finished = false
            job?.lat = location.latitude
            job?.long = location.longitude
            FirebaseService.firebaseService.postedJobs.append(job!)
        }
        else {
            self.job = Job(name: jobName, category: sectionName, lat: location.latitude, long: location.longitude, details: jobDetailsTxtView.text ?? "", distance: 0, finished: false)
            FirebaseService.firebaseService.postedJobs.append(job!)
        }
        // for testing in Xcode get image  and audio from asset folder and play with it
        // if image save to storage and get ref
            
            
        // if audio save to storage and get ref
        self.delegate?.saveChanges(job: self.job!)
        self.navigationController?.popViewController(animated: true)
        print("Notify helpers around")
        
        }
    }
    
    private func checkMicrophoneAuthorization() -> Bool{
        if SPPermission.microphone.isAuthorized{
            return true
        }
        else if SPPermission.microphone.isDenied {
            let data = deniedData(for: .notification)
            
            let alert = UIAlertController(title: data?.alertOpenSettingsDeniedPermissionTitle, message: data?.alertOpenSettingsDeniedPermissionDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionButtonTitle, style: .default, handler: { action in
                SPPermissionsOpener.openSettings()
            }))
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionCancelTitle, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.permissionsManager.delegate = self
            self.permissionsManager.present(on: self)
        }
        if SPPermission.notification.isAuthorized {
            return true
        }
        else {
            return false
        }
    }
    
    private func checkLocationAuthorization() -> Bool{
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
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
        if SPPermission.locationWhenInUse.isAuthorized {
            return true
        }
        else { return false }
    }
    private func determineUserLocation(){
        if CLLocationManager.locationServicesEnabled() {
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
    func notificationHanlder() {
        if SPPermission.notification.isAuthorized {
            sendNotification()
        }
        else if SPPermission.notification.isDenied {
            let data = deniedData(for: .notification)
            
            let alert = UIAlertController(title: data?.alertOpenSettingsDeniedPermissionTitle, message: data?.alertOpenSettingsDeniedPermissionDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionButtonTitle, style: .default, handler: { action in
                SPPermissionsOpener.openSettings()
            }))
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionCancelTitle, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            self.permissionsManager.delegate = self
            self.permissionsManager.present(on: self)
            if SPPermission.notification.isAuthorized {
                sendNotification()
            }
        }
//    UNUserNotificationCenter.current().getNotificationSettings { settings in
//        switch settings.authorizationStatus{
//        case .notDetermined:
////            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
////                if  granted == true && error == nil{
////                    self.sendNotification()
////                }
////            }
//            self.permissionsManager.delegate = self
//            self.permissionsManager.present(on: self)
//        case .denied:
//            return
//        case .authorized:
//            self.sendNotification()
//        case .provisional:
//            self.sendNotification()
//        case .ephemeral:
//            return
//        @unknown default:
//            return
//        }
//    }
}
    
func sendNotification() -> Void {
    let content = UNMutableNotificationContent()
    content.title = "There are lots of helpers around, make sure to finish the post sooner! "
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
    
    let notificationRequest = UNNotificationRequest.init(identifier: "activeUsersNotification", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(notificationRequest) { (error) in
        if error == nil{
        print("Notification scheduled succesfully")
        }
        else{
            print("There was an error with the notification.. \(String(describing: error))")
        }
    }
}
    /*
     Notification segment
    */
    
    
    
    func prepareCamera(){
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInMicrophone, .builtInTripleCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        print(availableDevices.description)
        captureDevice = availableDevices.first
        if availableDevices.count != 0 {
        beginSession()
        } else {print("No devices found")}
    }
    
    func beginSession() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error.localizedDescription)
//            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = previewLayer
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.layer.frame
        
        captureSession.startRunning()
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): NSNumber(value: kCVPixelFormatType_32BGRA)]
        
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput){
            captureSession.addOutput(dataOutput)
        }
        captureSession.commitConfiguration()
        
        let queue = DispatchQueue(label: "com.HristijanStojchevski.captureQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    func checkCameraAuth() -> Bool{
        if SPPermission.camera.isAuthorized {
            return true
        } else if SPPermission.camera.isDenied{
            // ask to enable from settings
            let data = deniedData(for: .camera)
            
            let alert = UIAlertController(title: data?.alertOpenSettingsDeniedPermissionTitle, message: data?.alertOpenSettingsDeniedPermissionDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionButtonTitle, style: .default, handler: { action in
                SPPermissionsOpener.openSettings()
            }))
            alert.addAction(UIAlertAction(title: data?.alertOpenSettingsDeniedPermissionCancelTitle, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            print("Ask to enable")
        } else {
            permissionsManager.delegate = self
            permissionsManager.present(on: self)
            if SPPermission.camera.isAuthorized {
                return true
            }
        }
        return false
    }
}

extension NewJobViewController: SPPermissionsDelegate {
    func didDenied(permission: SPPermission) {
        // Make an allert and tell him the only way he will have a fully funcional app if he goes to settings and changes the authorized permissions for this app
        _ = deniedData(for: permission)
    }
    func deniedData(for permission: SPPermission) -> SPPermissionDeniedAlertData? {
        if permission == .camera {
            let data = SPPermissionDeniedAlertData()
            data.alertOpenSettingsDeniedPermissionTitle = "Permission for the usage of camera was denied"
            data.alertOpenSettingsDeniedPermissionDescription = "Please, go to Settings and allow the use of camera."
            data.alertOpenSettingsDeniedPermissionButtonTitle = "Settings"
            data.alertOpenSettingsDeniedPermissionCancelTitle = "Cancel"
            return data
        } else if permission == .locationWhenInUse{
            let data = SPPermissionDeniedAlertData()
            data.alertOpenSettingsDeniedPermissionTitle = "Permission for the usage of location services was denied"
            data.alertOpenSettingsDeniedPermissionDescription = "Please, go to Settings and allow the use of location services."
            data.alertOpenSettingsDeniedPermissionButtonTitle = "Settings"
            data.alertOpenSettingsDeniedPermissionCancelTitle = "Cancel"
            return data
        } else if permission == .notification {
            let data = SPPermissionDeniedAlertData()
            data.alertOpenSettingsDeniedPermissionTitle = "Permission for the usage of notification services was denied"
            data.alertOpenSettingsDeniedPermissionDescription = "Please, go to Settings and allow the use of notification services."
            data.alertOpenSettingsDeniedPermissionButtonTitle = "Settings"
            data.alertOpenSettingsDeniedPermissionCancelTitle = "Cancel"
            return data
        }
        else{
            return nil
        }
    }
}

extension NewJobViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if takePhoto {
            print("Take picture")
            takePhoto = false
            
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer){
                DispatchQueue.main.async {
                    self.imageDescription?.image = image
                }
            }
            self.stopCaptureSession()
        }
    }
    func stopCaptureSession(){
        self.captureSession.stopRunning()
        
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput]{
            for input in inputs{
                self.captureSession.removeInput(input)
            }
        }
    }
    
    func getImageFromSampleBuffer (buffer: CMSampleBuffer) -> UIImage?{
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer){
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect){
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation:  .right)
            }
        }
        return nil
    }
}

extension NewJobViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // check for location authorization and if disabled ask to enable
       _ = checkLocationAuthorization()
    }
}

extension NewJobViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        imageDescription?.image = image
    }
}

