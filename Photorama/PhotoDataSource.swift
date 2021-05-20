import UIKit

class PhotoDataSource: NSObject, UICollectionViewDataSource {
    var photos = [Photo]()
    
    var favoritePhotos: [Photo] {
        photos.filter { $0.isFavorites }
    }
    
    var newPhotos: [Photo] {
        photos.filter { $0.isNew }
    }
    
    var tagDataSource = PhotoStore.shared.tagDataSource
    
    var tagPhotos: [Tag: [Photo]] {
        var dict = [Tag: [Photo]]()
        photos.forEach { photo in
            guard let photoTags = photo.tags as? Set<Tag> else {
                return
            }
            photoTags.forEach { tag in
                print(tag)
                dict[tag, default: []].append(photo)
            }
        }
//        tagDataSource?.tags.forEach { tag in
//            dict[tag] = photos.filter { photo in
//                guard let photoTags = photo.tags as? Set<Tag> else {
//                    return false
//                }
//               return photoTags.contains(tag)
//            }
//        }
        return dict
    }
    
    
    var segmentedIndex = 0
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch segmentedIndex {
        case 0...2:
            return 1
        case 3:
            print(tagPhotos,tagPhotos.count)
            return tagPhotos.count
        default:
            return 0
        }
    }
    
//    func indexTitles(for collectionView: UICollectionView) -> [String]? {
//        <#code#>
//    }
    
    func collectionView(_ collectionView: UICollectionView,  numberOfItemsInSection section: Int) -> Int {
        switch segmentedIndex {
        case 0:
            return photos.count
        case 1:
            return newPhotos.count
        case 2:
            return favoritePhotos.count
        case 3:
            guard let tag = tagDataSource?.tags[section], let photos = tagPhotos[tag] else {
                print(tagDataSource)
                return 0
            }
            print("there")
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
