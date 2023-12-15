//

import UIKit
struct Alert {
    private static func showBasicAlert(on vc: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async { vc.present(alert, animated: true, completion: nil) }
    }
    static func showNoTaskTitle(on vc: UIViewController) {
        showBasicAlert(on: vc, title: "😧 Uh Oh", message: "Give your task a name!")
    }
    static func showNoTaskDueDate(on vc: UIViewController) {
        showBasicAlert(on: vc, title: "🙁 Uh Oh", message: "Due date is empty")
    }
}
