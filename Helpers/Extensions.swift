
import Foundation

extension String {
    
    static let empty = ""
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
