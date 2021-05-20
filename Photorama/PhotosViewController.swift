//
//  ViewController.swift
//  Photorama
//
//  Created by Svetlio on 2.05.21.
//

import UIKit

class PhotosViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    var store = PhotoStore.shared
    let photoDataSource = PhotoDataSource()
    
    var tags: [Tag]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
        
        updateDataSource()
        
        store.fetchInterestingPhotos { _ in
            self.updateDataSource()
        }
        
        store.fetchAllTags { tagsResult in
            switch tagsResult {
            case let .success(tags):
                self.tags = tags
            case let .failure(error):
                print("Error fetching tags: \(error).")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadSections(IndexSet(integer: 0))
        //collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photos: [Photo]
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            photos = photoDataSource.photos
        case 1:
            photos = photoDataSource.newPhotos
        case 2:
            photos = photoDataSource.favoritePhotos
        default:
            photos = photoDataSource.photos
        }
        
        let photo = photos[indexPath.row]
        
        store.fetchImage(for: photo) { (result) -> Void in
            guard let photoIndex = photos.firstIndex(of: photo),
                  case let .success(image) = result else {
                return
            }
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            if let cell = self.collectionView.cellForItem(at: photoIndexPath)
                as? PhotoCollectionViewCell {
                cell.update(displaying: image)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showPhoto":
            if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
                let photo = photoDataSource.photos[selectedIndexPath.row]
                
                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = store
            }
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
    }
    
    private func updateDataSource() {
        store.fetchAllPhotos { photosResult in
            switch photosResult {
            case let .success(photos):
                self.photoDataSource.photos = photos
            case .failure:
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    @IBAction func photosTypeChanged(_ sender: Any) {
        photoDataSource.segmentedIndex = segmentedControl.selectedSegmentIndex
        collectionView.reloadData()
    }
}

