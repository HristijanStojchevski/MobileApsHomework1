//
//  ElderJobsViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/28/21.
//

import UIKit
private let JobCellId = "JobCellID"
class ElderJobsViewController: UIViewController {
    

    @IBOutlet weak var JobTableView: UITableView!
    
    var category = ""
//    var jobs = [ "Maintainance": ["Air conditioner", "Oil change"], "Repairs": ["Leaky pipes", "Fix door handle", "Change falt tire", "Electricity went down"], "Cleaning": ["Mopping floors", "Cleaning dishes", "Laundry", "Whiping dust"],
//                 "Shopping": ["Groceries", "Food", "Materials"], "Construction": ["Repainting", "Fill a hole in the wall", "Put tiles in the backyard"], "Gardening": ["Plant a tree", "Mow the grass"]
//    ]
    var jobs: Dictionary = [String:[String]]()
//    var sectionNames = ["Maintainance", "Repairs", "Cleaning", "Shopping", "Construction","Gardening"]
    var sectionNames: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sectionNames = Array(jobs.keys)
        print("Init setup \(sectionNames)")
        
        FirebaseService.firebaseService.getJobCategories { (categories) in
            self.sectionNames = categories
            
            self.sectionNames.removeAll { (key) -> Bool in
                return key == self.category
            }
            self.sectionNames.sort { (section1, section2) -> Bool in
                return section1 < section2
            }
            self.sectionNames.insert(self.category, at: 0)
            
            self.jobs.removeAll()
            for section in self.sectionNames {
                self.jobs[section] = []
                FirebaseService.firebaseService.getJobsByCategory(category: section).getDocuments { (snap, err) in
                    if let err = err {
                        print("Err at getting jobs")
                        print(err)
                    }
                    else {
                        for doc in snap!.documents {
                            let docTitle = doc.get("title") as! String
                            if self.jobs[section]!.contains(docTitle) {
                            }
                            else {
                                self.jobs[section]?.append(docTitle)
                            }
                        }
                        
                        self.JobTableView.reloadData()
                    }
                    
                }
                
            }
            
        }
        
        // Do any additional setup after loading the view.
        
        self.JobTableView.delegate = self
        self.JobTableView.dataSource = self
        self.JobTableView.tableFooterView = UIView()
        
        let profile = UIBarButtonItem(title: "Profile", style: .plain, target: self, action: #selector(profileTapped))
        let logOut = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        
        navigationItem.rightBarButtonItems = [profile, logOut]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func openItemDetail(indexPath: IndexPath){
        let vc = storyboard?.instantiateViewController(identifier: "NewJobViewController") as! NewJobViewController
        let sectionName = sectionNames[indexPath.section]
        if indexPath.row != jobs[sectionName]?.count ?? 20{
            let job = jobs[sectionName]?[indexPath.row]
            vc.jobName = job ?? ""
            vc.sectionName = sectionName
            vc.job = Job(name: job ?? "", category: sectionName, lat: 0, long: 0, details: "", distance: 0, finished: false)
        }
        vc.newJob = true
        vc.sectionName = sectionName
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @objc func logout(){
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: "userLogIn")
        defaults.removeObject(forKey: "userCredentials")
        self.navigationController?.popToRootViewController(animated: true)
    }
    @objc func profileTapped(){
        let vc = storyboard?.instantiateViewController(identifier: "ElderProfileViewController") as! ProfileViewController
        self.present(vc, animated: true, completion: nil)
//        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ElderJobsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return jobs.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionName = sectionNames[section]
        return (jobs[sectionName]?.count ?? 0) + 1 // new job from that category type
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionName = sectionNames[indexPath.section]
        let cell = JobTableView?.dequeueReusableCell(withIdentifier: JobCellId, for: indexPath) as! JobTableViewCell
        if indexPath.row == jobs[sectionName]?.count ?? 20{
            cell.JobLabel!.text = "Other"
        }
        else {
            let job = jobs[sectionName]?[indexPath.row]
            cell.JobLabel!.text = job
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
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionNames[section]
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let size = self.view.frame
        return size.height / 10
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .gray
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openItemDetail(indexPath: indexPath)
    }
    
}

extension ElderJobsViewController: NewJobDelegate {
    func enrollJob(job: Job) {
        print("")
    }
    
    func deleteJob(job: Job) {
        print("")
    }
    
    func cancelJob(job: Job) {
        print("")
    }
    
    func saveChanges(job: Job) {
        if !(jobs[job.category]?.contains(job.name))!{
            jobs[job.category]?.append(job.name)
        }
        self.JobTableView.reloadData()
    }
}
