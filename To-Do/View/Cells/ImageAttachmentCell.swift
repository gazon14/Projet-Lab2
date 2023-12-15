

import UIKit

class ImageAttachmentCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    
    func setImage(_ image: UIImage?) {
        imageView.image = image
    }
}
