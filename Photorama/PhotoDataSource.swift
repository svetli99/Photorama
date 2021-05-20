import UIKit

class PhotoDataSource: NSObject, UICollectionViewDataSource {
    var photos = [Photo]()
    
    var favoritePhotos: [Photo] {
        photos.filter { $0.isFavorites }
    }
    
    var newPhotos: [Photo] {
        photos.filter { $0.isNew }
    }
    
    var segmentedIndex = 0
    
    func collectionView(_ collectionView: UICollectionView,  numberOfItemsInSection section: Int) -> Int {
        switch segmentedIndex {
        case 0:
            return photos.count
        case 1:
            return newPhotos.count
        case 2:
            return favoritePhotos.count
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
