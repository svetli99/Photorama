import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    func update(displaying image: UIImage?) {
        imageView.image = image
        if image != nil {
            spinner.stopAnimating()
        } else {
            spinner.startAnimating()
        }
    }
}
