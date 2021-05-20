import UIKit

class PhotoDataSource: NSObject, UICollectionViewDataSource {
    var photos = [Photo]()
    
    var favoritePhotos: [Photo] {
        photos.filter { $0.isFavorites }
    }
    
    var newPhotos: [Photo] {
        photos.filter { $0.isNew }
    }
    
    let store = PhotoStore.shared
    
    var tagPhotos: [Tag: [Photo]] {
        var dict = [Tag: [Photo]]()
        photos.forEach { photo in
            guard let photoTags = photo.tags as? Set<Tag> else {
                return
            }
            photoTags.forEach { tag in
                dict[tag, default: []].append(photo)
            }
        }
        return dict
    }
    
    
    var segmentedIndex = 0
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch segmentedIndex {
        case 0...2:
            return 1
        case 3:
            return tagPhotos.count
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! PhotoSectionHeaderView
        header.label.text = store.tags![indexPath.section].name
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,  numberOfItemsInSection section: Int) -> Int {
        switch segmentedIndex {
        case 0:
            return photos.count
        case 1:
            return newPhotos.count
        case 2:
            return favoritePhotos.count
        case 3:
            let tag = store.tags![section]
            let photos = tagPhotos[tag]!
            return photos.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let identifier = "PhotoCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PhotoCollectionViewCell
        cell.update(displaying: nil)
        return cell
    }
}

class PhotoSectionHeaderView: UICollectionReusableView {
    @IBOutlet weak var label: UILabel!
}
