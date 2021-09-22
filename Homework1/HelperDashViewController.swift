//
//  HeperDashViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/30/21.
//
import UIKit
import Firebase

private let jobFinishedCellID = "JobsFinishedID"
private let jobEnrolledCellID = "JobsEnrolledID"
class HelperDashViewController: UIViewController {
    
    @IBOutlet weak var helperName: UITextField!
    @IBOutlet weak var helperSurname: UITextField!
    
    @IBOutlet weak var enrolledTableView: UITableView!
    
    @IBOutlet weak var finishedTableView: UITableView!
    var finishedSectionNames: [String] = []
    var enrolledSectionNames: [String] = []
    
//    let jobs = [ Job(name: "Mow the grass", category: "Gardening", lat: 41.043341, long: 21.340759, details: "Mow the grass in the backyard", distance: 0, finished: true),
//                 Job(name: "Repainting", category: "Construction", lat: 41.0, long: 22.34, details: "My walls need some love after a couple of years", distance: 0, finished: false),
//                 Job(name: "Repainting", category: "Construction", lat: 46, long: 40, details: "We are smokers", distance: 0, finished: true),
//                 Job(name: "Change falt tire", category: "Repairs", lat: 50, long: 40, details: "Stuck on the road with a flat tire. Too old to change it", distance: 0, finished: true),
//                 Job(name: "Electricity went down", category: "Repairs", lat: 25, long: 30, details: "I don't know what happened but I am left out with zero electricity", distance: 0, finished: false)
//             ]
    var jobs: [Job] = []
    var finishedJobs: [Job] = []
    var enrolledJobs: [Job] = []
    
    var loadDataFromService = true
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.enrolledTableView.delegate = self
        self.enrolledTableView.dataSource = self
        self.finishedTableView.delegate = self
        self.finishedTableView.dataSource = self
        // We search all the jobs from firebase that this user has link to
        
        helperName.text = "Helper Name Loading"
        helperSurname.text = "Helper Surname Loading"
        finishedJobs.removeAll()
        enrolledJobs.removeAll()
        finishedSectionNames.removeAll()
        enrolledSectionNames.removeAll()
        
        FirebaseService.firebaseService.enrolledJobs.removeAll()
        FirebaseService.firebaseService.finishedJobs.removeAll()
        loadDataFromService = false
        FirebaseService.firebaseService.getAllHelperJobs { (helperJob, elder) -> (Void) in
            if helperJob.finished {
                elder.getDocument(completion: { (elderRef, err) in
                    if let elderErr = err {
                        print(elderErr)
                    } else {
                        if !self.finishedSectionNames.contains(helperJob.category){
                            self.finishedSectionNames.append(helperJob.category)
                        }
                        helperJob.details = "Creator: \(elderRef?.get("name") ?? "CREATOR NOT FOUND !!!") " + helperJob.details
                       
                        FirebaseService.firebaseService.finishedJobs.append(helperJob)
                        self.finishedJobs = FirebaseService.firebaseService.finishedJobs
                        self.finishedTableView.reloadData()
                    }
                })
            }
            else {
                elder.getDocument(completion: { (elderRef, err) in
                    if let elderErr = err {
                        print(elderErr)
                    } else {
                        helperJob.details = "Creator: \(elderRef?.get("name") ?? "CREATOR NOT FOUND !!!") " + helperJob.details
                        if !self.enrolledSectionNames.contains(helperJob.category){
                            self.enrolledSectionNames.append(helperJob.category)
                        }
                        FirebaseService.firebaseService.enrolledJobs.append(helperJob)
                        self.enrolledJobs = FirebaseService.firebaseService.enrolledJobs
                        self.enrolledTableView.reloadData()
                    }
                    
                })
                
            }
        } user_info: { (user_name, user_surname) -> (Void) in
            self.helperName.text = user_name
            self.helperSurname.text = user_surname
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        if loadDataFromService {
            print(FirebaseService.firebaseService.enrolledJobs)
            self.enrolledJobs = FirebaseService.firebaseService.enrolledJobs
            self.finishedJobs = FirebaseService.firebaseService.finishedJobs
            self.enrolledJobs.forEach { (job) in
                if !self.enrolledSectionNames.contains(job.category){
                    self.enrolledSectionNames.append(job.category)
                }
            }
            self.finishedJobs.forEach { (job) in
                if !self.finishedSectionNames.contains(job.category){
                    self.finishedSectionNames.append(job.category)
                }
            }
            self.enrolledTableView.reloadData()
            self.finishedTableView.reloadData()
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

}

extension HelperDashViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.finishedTableView {
            return finishedSectionNames[section]
        }
        else if tableView == self.enrolledTableView {
            return enrolledSectionNames[section]
        }
        else { return "" }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.finishedTableView {
            return finishedSectionNames.count
        }
        else if tableView == self.enrolledTableView {
            return enrolledSectionNames.count
        }
        else { return 0 }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.finishedTableView {
            let sectionName = finishedSectionNames[section]
            
            return finishedJobs.filter { (job) -> Bool in
                return job.category == sectionName
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
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .gray
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var sectionName = ""
        var cell: JobListTableViewCell! = nil
        var job = Job(name: "", category: "", lat: 0, long: 0, details: "", distance: 0, finished: false)
        if tableView == self.finishedTableView {
            sectionName = finishedSectionNames[indexPath.section]
            cell = finishedTableView?.dequeueReusableCell(withIdentifier: jobFinishedCellID, for: indexPath) as? JobListTableViewCell
            job = finishedJobs.filter { (job) -> Bool in
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
        if tableView == self.finishedTableView {
            sectionName = finishedSectionNames[indexPath.section]
            job = finishedJobs.filter({ (helperJob) -> Bool in
                return helperJob.category == sectionName
            })[indexPath.row]
            vc.jobName = job?.name ?? ""
            vc.jobDetails = job?.details ?? ""
            vc.helperFinished = true
        }
        else if tableView == self.enrolledTableView {
            sectionName = enrolledSectionNames[indexPath.section]
            job = enrolledJobs.filter({ (helperJob) -> Bool in
                return helperJob.category == sectionName
            })[indexPath.row]
            vc.jobName = job?.name ?? ""
            vc.jobDetails = job?.details ?? ""
            vc.helperEnrolled = true
        }
        vc.delegate = self
        vc.job = job
        vc.jobRef = job?.jobRef
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension HelperDashViewController: NewJobDelegate {
    func saveChanges(job: Job) {
        print("Save changes")
    }
    
    func enrollJob(job: Job) {
        print("Enrolled")
    }
    
    func deleteJob(job: Job) {
        FirebaseService.firebaseService.finishedJobs.remove(at: finishedJobs.firstIndex(of: job)!)
        finishedJobs = FirebaseService.firebaseService.finishedJobs
        if !finishedJobs.contains(where: { (jb) -> Bool in
            return jb.category == job.category
        }) {
            finishedSectionNames.remove(at: finishedSectionNames.firstIndex(of: job.category)!)
        }
        self.finishedTableView.reloadData()
    }
    
    func cancelJob(job: Job) {
        enrolledJobs.remove(at: enrolledJobs.firstIndex(of: job)!)
        FirebaseService.firebaseService.enrolledJobs = enrolledJobs
        FirebaseService.firebaseService.postedJobs.append(job)
        if !enrolledJobs.contains(where: { (jb) -> Bool in
            return jb.category == job.category
        }) {
            enrolledSectionNames.remove(at: enrolledSectionNames.firstIndex(of: job.category)!)
        }
        self.enrolledTableView.reloadData()
        
    }
    
    
}
