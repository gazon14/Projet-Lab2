import Foundation
import CoreData

extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    // Existing properties...

    // Add a to-many relationship to notes
    @NSManaged public var notes: Set<Note>

}
