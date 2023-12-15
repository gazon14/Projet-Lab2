
import UIKit

extension UITextView{
    func addBorder(){
        self.layer.cornerRadius = 6
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.separator.cgColor
    }
}
