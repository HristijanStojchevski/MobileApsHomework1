//
//  FirebaseService.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/22/21.
//

import Foundation
import Firebase

class FirebaseService{
    
//    var jobListing: [Job] = []
    
    var enrolledJobs: [Job] = []
    
    var finishedJobs: [Job] = []
    
    var postedJobs: [Job] = []
    
    var deviceToken: String = "fromSimulator"
    
    static let firebaseService = FirebaseService()
    
    let rootRef = Firestore.firestore()
    
    func getCollection(collectionPath: String) -> CollectionReference {
        let collectionRef = self.rootRef.collection(collectionPath)
        return collectionRef
    }
    
    func getElderCollection() -> CollectionReference {
        return self.rootRef.collection("/users/groups/elders")
    }
    
    func getHelperCollection() -> CollectionReference {
        return self.rootRef.collection("/users/groups/helpers")
    }
    
    func getAllHelperJobs(completion: @escaping (Job, DocumentReference)  -> (Void), user_info: @escaping (String?, String?) -> (Void)) -> Void{
        self.getLoggedInUser { (userRef) in
            userRef.getDocument { (user, err) in
                if let err = err {
                    print(err)
                }
                else {
                    let userData = user?.data()
                    let user_name = userData?["name"] as? String
                    let user_surname = userData?["surname"] as? String
                    user_info(user_name, user_surname)
                    let jobRefArray = userData?["jobs"] as? [DocumentReference]
                    for i in 0..<jobRefArray!.count {
                        let category = jobRefArray![i].parent.parent?.documentID
                        jobRefArray![i].getDocument { (job, err) in
                            if let jobErr = err {
                                print("Error with job \(jobErr)")
                            }
                            else {
                                let jobData = job?.data()
                                let location = jobData!["location"] as? GeoPoint
                                let helperJob = Job(name: jobData!["title"] as! String, category: category!, lat: location?.latitude ?? 0, long: location?.longitude ?? 0, details: jobData!["description"] as! String, distance: 0, finished: jobData!["finished"] as! Bool)
                                helperJob.setJobRef(jobRef: job!.reference)
                                completion(helperJob, (jobData!["creator"] as? DocumentReference)!)
                            }
                        }
                    }
                    
                    
                }
            }
        }
    }
    
    func getAllPostedJobs(completion: @escaping (Job) -> (Void)) -> Void{
        self.getJobCategories{ (categories) in
            for category in categories {
                let jobCollectionRef = self.getJobsByCategory(category: category)
                // make sure to create a Job() with category and rest of fields
                jobCollectionRef.getDocuments { (jobSnap, err) in
                    if let err = err {
                        print("Map job fetch error \(err)")
                    }
                    else {
                        if let jobSnap = jobSnap, !jobSnap.isEmpty {
                            for job in jobSnap.documents {
                                let jobData = job.data()
                                if jobData["enrolled"] as? Bool == false {
                                    let elder = jobData["creator"] as? DocumentReference
                                    elder?.getDocument(completion: { (elderSnap, err) in
                                        if let elderErr = err {
                                            print(elderErr)
                                        } else {
                                            
                                            let location = jobData["location"] as? GeoPoint
                                            let nJob = Job(name: job["title"] as? String ?? "", category: job.reference.parent.parent?.documentID ?? "", lat: location?.latitude ?? 0, long: location?.longitude ?? 0, details: job["description"] as? String ?? "", distance: 0, finished: false)
                                            nJob.setJobRef(jobRef: job.reference)
                                            nJob.details = "Creator: \(elderSnap?.get("name") ?? "CREATOR NOT FOUND !!!") " + nJob.details
                                            self.postedJobs.append(nJob)
                                            completion(nJob)
                                        }
                                    })
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getJobCategories(completion: @escaping ([String]) -> Void){
        var categories: [String] = []
        self.rootRef.collection("jobCategories").getDocuments { (snap, err) in
            if let err = err {
                print(err)
                completion([])
            }
            else {
                for doc in snap!.documents {
                    categories.append(doc.documentID)
                }
                completion(categories)
            }
        }
    }
    
    func getJobsByCategory( category: String) -> CollectionReference {
        
        return self.rootRef.collection("/jobCategories/\(category)/jobs")
    }
    
    func assignJob(jobID: String, category: String, completion: @escaping (DocumentReference) -> Void) -> Void {
        self.getLoggedInUser { (docRef) in
            let refPath = docRef.path
            let relevantJob = self.getJobsByCategory(category: category).document(jobID)
            relevantJob.setData(["helper": refPath], merge: true)
            docRef.setData(["job": relevantJob.path], merge: true)
            completion(relevantJob)
        }
    }
    
    func createJob(category: String,jobData: [String : Any]) -> DocumentReference {
        let relJob = self.getJobsByCategory(category: category).document()
        let defaults = UserDefaults.standard
        var jobD = jobData
        if let userCreds = defaults.stringArray(forKey: "userCredentials"){
            let username = userCreds[0]
            let role = userCreds[1]
            
            print("Role: \(role)")
            if role == "Helper" {
                let loggedInUser = self.getHelperCollection().document(username)
                loggedInUser.setData(["jobs": FieldValue.arrayUnion([relJob])], merge: true)
                jobD["creator"] = loggedInUser
//                loggedInUser.setData(["job": relJob.path], merge: true)
            }
            else if role == "Elder" {
                let loggedInUser = self.getElderCollection().document(username)
                jobD["creator"] = loggedInUser
                loggedInUser.setData(["jobs": FieldValue.arrayUnion([relJob])], merge: true)
            }
        }
        relJob.setData(jobD)
        print("Completed userRef")
        return relJob
    }
    
    func getLoggedInUser(completion: @escaping (DocumentReference) -> Void) -> Void {
        // get from user defaults, loggedIn user, search User by username, name, surname in firebase and get the firebase id
        let defaults = UserDefaults.standard
        if let userCreds = defaults.stringArray(forKey: "userCredentials"){
            let username = userCreds[0]
            let role = userCreds[1]
            if role == "Helper" {
                let loggedInUser = self.getHelperCollection().document(username)
                completion(loggedInUser)
            }
            else if role == "Elder" {
                let loggedInUser = self.getElderCollection().document(username)
                completion(loggedInUser)
            }
            
        }
    }
    
    func deleteDocument(docRef: DocumentReference) -> Void {
        print("Deleting document -> ", docRef.documentID)
        docRef.delete { (error) in
            if error == nil {
                print("Successful deletion !")
            }
        }
    }
    
    //  // Adding new document to collection with new ID. ID could be auto generated
    //    let elder13Ref = usersRef.document("groups").collection("elders").document("elder-13")
    //    elder13Ref.setData([ "name": "XcodeUser", "age": 18])
    func addDocument(collectionRef: CollectionReference, documentData: [String : Any] ,documentId:String = "") -> DocumentReference {
        if documentId.isEmpty {
            let docRef = collectionRef.document()
            docRef.setData(documentData)
            return docRef
        }
        else {
            let docRef = collectionRef.document(documentId)
            docRef.setData(documentData, merge: true)
            return docRef
        }
    }
    
    func updateDocument(docRef: DocumentReference, dataUpdate: [String : Any]) -> DocumentReference {
        docRef.setData(dataUpdate, merge: true) // maybe update data ?
        return docRef
    }
    
    func getUserPass(username: String, completion: @escaping (String, Bool, Bool) -> Void){
        var passHash = ""
       
        let helperRef = self.getHelperCollection().document(username)
        helperRef.getDocument { (helperSnap, err) in
            if let err = err {
                print("Err with fetching data for this username -> \(username).")
                print(err)
            }
            else if let helperSnap = helperSnap {
                let isHelper = true
                if helperSnap.exists {
                    passHash = helperSnap.get("pass") as! String
                    let userExists = true
                    completion(passHash, isHelper, userExists)
                } else {
                    completion(passHash, isHelper, false)
                }
            }
        }
        let elderRef = self.getElderCollection().document(username)
        elderRef.getDocument { (elderSnap, err) in
            if let err = err {
                print("Err with fetching data for this username -> \(username).")
                print(err)
            }
            else if let elderSnap = elderSnap {
                let isHelper = false
                if elderSnap.exists {
                    passHash = elderSnap.get("pass") as! String
                    let userExists = true
                    completion(passHash, isHelper, userExists)
                } else {
                    completion(passHash, isHelper, false)
                }
            }
        }
//        self.getHelperCollection().getDocuments { (snap, err) in
//            if let err = err {
//                print("Err \(err)")
//            }
//            else {
//                for doc in snap!.documents {
//                    let fireUser = doc.get("username") as! String
//                    if username == fireUser {
//                        print("ENTERED")
//                        userExists = true
//                        helper = true
//                        passHash = doc.get("pass") as! String
//                        completion(passHash, helper, userExists)
//                        break
//                    }
//                    else {
//                        passHash = "-"
//                    }
//                }
//            }
//        }
//        self.getElderCollection().getDocuments { (snap, err) in
//            if let err = err {
//                print("Err \(err)")
//            }
//            else {
//                for doc in snap!.documents {
//                    let fireUser = doc.get("username") as! String
//                    if username == fireUser {
//                        print("Entered")
//                        userExists = true
//                        passHash = doc.get("pass") as! String
//                        completion(passHash, helper, userExists)
//                        break
//                    }
//                }
//                if !userExists {
//                    completion(passHash, helper, userExists)
//                }
//            }
//        }
    }
}
