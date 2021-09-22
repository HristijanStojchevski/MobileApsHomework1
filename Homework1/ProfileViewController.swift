//
//  ProfileViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/30/21.
//

import UIKit
import Firebase

private let jobPostedCellID = "JobPostsID"
private let jobEnrolledCellID = "JobEnrolledID"
class ProfileViewController: UIViewController {
    
    @IBOutlet weak var elderName: UITextField!
    @IBOutlet weak var elderSurname: UITextField!
    
    @IBOutlet weak var enrolledTableView: UITableView!
    @IBOutlet weak var postedTableView: UITableView!
    
//    var jobs = [ Job(name: "Mow the grass", category: "Gardening", lat: 41.043341, long: 21.340759, details: "Mow the grass in the backyard", distance: 0, enrolled: true),
//                 Job(name: "Repainting", category: "Construction", lat: 41.0, long: 22.34, details: "My walls need some love after a couple of years", distance: 0, enrolled: false),
//                 Job(name: "Repainting", category: "Construction", lat: 46, long: 40, details: "We are smokers", distance: 0, enrolled: true),
//                 Job(name: "Change falt tire", category: "Repairs", lat: 50, long: 40, details: "Stuck on the road with a flat tire. Too old to change it", distance: 0, enrolled: true),
//                 Job(name: "Electricity went down", category: "Repairs", lat: 25, long: 30, details: "I don't know what happened but I am left out with zero electricity", distance: 0, enrolled: false)
//             ]
    var jobs: [Job] = []
    var enrolledJobs: [Job] = []
    var postedJobs: [Job] = []
    var postedSectionNames: [String] = []
    var enrolledSectionNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.postedTableView.delegate = self
        self.postedTableView.dataSource = self
        self.enrolledTableView.delegate = self
        self.enrolledTableView.dataSource = self
        // Do any additional setup after loading the view.
        
        self.elderName.text = "Waiting for name"
        self.elderSurname.text = "Waiting for surname"
        
        FirebaseService.firebaseService.getLoggedInUser { (userRef) in
            userRef.getDocument { (user, err) in
                if let err = err {
                    print(err)
                }
                else {
                    let userData = user?.data()
                    self.elderName.text = userData?["name"] as? String
                    self.elderSurname.text = userData?["surname"] as? String
                    
                    let jobRefArray = userData?["jobs"] as? [DocumentReference]
                    print("Structure of jobArray is : \(String(describing: jobRefArray))")
                    for i in 0..<jobRefArray!.count {
                        let category = jobRefArray![i].parent.parent?.documentID
                        jobRefArray![i].getDocument { (job, err) in
                            if let jobErr = err {
                                print("Error with job \(jobErr)")
                            }
                            else {
                                let jobData = job?.data()
                                let location = jobData!["location"] as? GeoPoint
                                print("Location : \(String(describing: location)) and latitude: \(location?.latitude ?? 0) and longitude: \(location?.longitude ?? 0)")
                                let elderJob = Job(name: jobData!["title"] as! String, category: category!, lat: location?.latitude ?? 0, long: location?.longitude ?? 0, details: jobData!["description"] as! String, distance: 0, finished: jobData!["finished"] as! Bool)
                                
                                elderJob.setJobRef(jobRef: job!.reference)
                                elderJob.setEnrolled(enrolled: jobData!["enrolled"] as? Bool ?? false)
                                if elderJob.enrolled == false {
                                    if !self.postedSectionNames.contains(elderJob.category){
                                        self.postedSectionNames.append(elderJob.category)
                                    }
                                    self.postedJobs.append(elderJob)
                                    self.postedTableView.reloadData()
                                }
                                else {
                                    let helper = jobData!["helper"] as? DocumentReference
                                    helper?.getDocument(completion: { (helperRef, err) in
                                        if let helperErr = err {
                                            print(helperErr)
                                        } else {
                                            elderJob.details = "Helper: \(helperRef?.get("name") ?? "Error finding name"). " + elderJob.details
                                            if !self.enrolledSectionNames.contains(elderJob.category){
                                                self.enrolledSectionNames.append(elderJob.category)
                                            }
                                            self.enrolledJobs.append(elderJob)
                                        }
                                        self.enrolledTableView.reloadData()
                                    })
                                    
                                }
                                
                            }
                        }
                    }
                    
                    
                }
            }
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

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.postedTableView {
            return postedSectionNames.count
        }
        else if tableView == self.enrolledTableView {
            return enrolledSectionNames.count
        }
        else { return 0 }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.postedTableView {
            let sectionName = postedSectionNames[section]
            return postedJobs.filter { (elderJob) -> Bool in
                return elderJob.category == sectionName
            }.count
        }
        else if tableView == self.enrolledTableView {
            let sectionName = enrolledSectionNames[section]
            return enrolledJobs.filter { (job) -> Bool in
                return job.category == sectionName
            }.count
        }
        else { return 0 }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.postedTableView {
            return postedSectionNames[section]
        }
        else if tableView == self.enrolledTableView {
            return enrolledSectionNames[section]
        }
        else { return "" }
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .gray
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var sectionName = ""
        var cell: JobListTableViewCell! = nil
        var job = Job(name: "", category: "", lat: 0, long: 0, details: "", distance: 0, finished: false)
        if tableView == self.postedTableView {
            sectionName = postedSectionNames[indexPath.section]
            cell = postedTableView?.dequeueReusableCell(withIdentifier: jobPostedCellID, for: indexPath) as? JobListTableViewCell
            job = postedJobs.filter { (job) -> Bool in
                return job.category == sectionName
            }[indexPath.row]
        }
        else if tableView == self.enrolledTableView {
            sectionName = enrolledSectionNames[indexPath.section]
            cell = enrolledTableView?.dequeueReusableCell(withIdentifier: jobEnrolledCellID, for: indexPath) as? JobListTableViewCell
            job = enrolledJobs.filter { (job) -> Bool in
                return job.category == sectionName
            }[indexPath.row]
        }
        
        cell.jobName.text = job.name
        cell.jobDescr.text = job.details
        
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
        var sectionName = ""
        var job: Job? = nil
        if tableView == self.postedTableView {
            sectionName = postedSectionNames[indexPath.section]
            job = postedJobs.filter({ (helperJob) -> Bool in
                return helperJob.category == sectionName
            })[indexPath.row]
            vc.jobName = job?.name ?? ""
            vc.jobDetails = job?.details ?? ""
        }
        else if tableView == self.enrolledTableView {
            sectionName = enrolledSectionNames[indexPath.section]
            job = enrolledJobs.filter({ (helperJob) -> Bool in
                return helperJob.category == sectionName
            })[indexPath.row]
            vc.jobName = job?.name ?? ""
            vc.jobDetails = job?.details ?? ""
            vc.enrolledJob = true
        }
        vc.jobRef = job?.jobRef
        vc.job = job
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
}

extension ProfileViewController: NewJobDelegate {
    func saveChanges(job: Job) {
        self.postedJobs.remove(at: self.postedJobs.firstIndex(where: { (jb) -> Bool in
            return jb.name == job.name && jb.lat == job.lat && jb.long == job.long
        })!)
        self.postedJobs.append(job)
        self.postedTableView.reloadData()
//        self.viewDidAppear(true)
    }
    
    func enrollJob(job: Job) {
        print("")
    }
    
    func deleteJob(job: Job) {
        self.enrolledJobs.remove(at: self.enrolledJobs.firstIndex(of: job)!)
        self.enrolledTableView.reloadData()
        print("Just deleted a job")
    }
    
    func cancelJob(job: Job) {
        print("")
    }
    
    
}
