//
//  ElderCategoriesViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/23/21.
//

import UIKit

private let reuseId = "CategoryCellID"
class ElderCategoriesViewController: UIViewController {
    
    @IBOutlet weak var catCollectionView: UICollectionView!
    
    let firebase = FirebaseService()
    
    let jobTableViewID = "ElderJobsViewController"
    
    var catMockList = ["Maintainance", "Repairs", "Cleaning", "Shopping", "Construction","Gardening"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firebase.getJobCategories { (categories) in
            self.catMockList = categories
            
            self.catCollectionView?.dataSource = self
            self.catCollectionView?.delegate = self
    //        catCollectionView?.allowsSelection = true
            // Do any additional setup after loading the view.
            
            self.catCollectionView.collectionViewLayout = ElderCategoriesViewController.createLayout()
            // Registering the cell will create a new cell and override the one from
            // storyboard. You would need to override the init method of the custom cell
            // and define the view content programmatically
    //        self.catCollectionView!.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: reuseId)
        }
        
        
        let profile = UIBarButtonItem(title: "Profile", style: .plain, target: self, action: #selector(profileTapped))
        let logOut = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        
        navigationItem.rightBarButtonItems = [profile, logOut]
    }
    
    static func createLayout() -> UICollectionViewCompositionalLayout{
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/4)),
                                                       subitem: item,
                                                       count: 1)
        let section = NSCollectionLayoutSection(group: group)
        
        return UICollectionViewCompositionalLayout(section: section)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
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

extension ElderCategoriesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return catMockList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = catCollectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! CategoryCollectionViewCell
        cell.layer.cornerRadius = self.view.frame.width/10
        let category = catMockList[indexPath.row]
        cell.backgroundColor = .green
        cell.categoryLabel!.text = category
        cell.categoryLabel!.textColor = .white
        
//        cell.DrinkImage!.image = UIImage.init(named: drink.imageName)
//        cell.DrinkImage!.image = UIImage.init(systemName: "cloud")
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: jobTableViewID) as! ElderJobsViewController
        vc.category = catMockList[indexPath.row]
//        self.present(vc, animated: true, completion: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
