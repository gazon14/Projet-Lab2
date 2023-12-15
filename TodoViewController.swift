
import UIKit
import CoreData

class TodoViewController: UITableViewController {
    @IBOutlet weak var todoTableView: UITableView!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    var searchController: UISearchController!
    var resultsTableController: ResultsTableController!
    var todoList : [Task] = []
    var lastIndexTapped : Int = 0
    var moc: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<Task>!
    lazy var defaultFetchRequest: NSFetchRequest<Task> = {
        let fetchRequest : NSFetchRequest<Task> = Task.fetchRequest()
        return fetchRequest
    }()
    var currentSelectedSortType: SortTypesAvailable = .sortByNameAsc
    
    var hapticNotificationGenerator: UINotificationFeedbackGenerator? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showOnboardingIfNeeded()
        setupEmptyState()
        loadData()
        setupSearchController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationItem.searchController = searchController
    }
    func loadData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let persistenceContainer = appDelegate.persistentContainer
        moc = persistenceContainer.viewContext
        defaultFetchRequest.sortDescriptors = currentSelectedSortType.getSortDescriptor()
        defaultFetchRequest.predicate = NSPredicate(format: "isComplete = %d", false)
        setupFetchedResultsController(fetchRequest: defaultFetchRequest)
        if let objects = fetchedResultsController.fetchedObjects {
            self.todoList = objects
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    func setupFetchedResultsController(fetchRequest: NSFetchRequest<Task>) {
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    @IBAction func addTasksTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Constants.Segue.taskToTaskDetail, sender: false)
    }
    
    @IBAction func sortButtonTapped(_ sender: UIBarButtonItem) {
        showSortAlertController()
    }
    func starTask(at index : Int){
        todoList[index].isFavourite = todoList[index].isFavourite ? false : true
        updateTask()
    }
    func deleteTask(at index : Int){
        hapticNotificationGenerator = UINotificationFeedbackGenerator()
        hapticNotificationGenerator?.prepare()
        
        let element = todoList.remove(at: index)
        moc.delete(element)
        do {
            try moc.save()
            hapticNotificationGenerator?.notificationOccurred(.success)
        } catch {
            todoList.insert(element, at: index)
            print(error.localizedDescription)
            hapticNotificationGenerator?.notificationOccurred(.error)
        }
        tableView.reloadData()
        hapticNotificationGenerator = nil
    }
    func completeTask(at index : Int){
        todoList[index].isComplete = true
        todoList.remove(at: index)
        updateTask()
        tableView.reloadData()
    }
    func updateTask(){
        hapticNotificationGenerator = UINotificationFeedbackGenerator()
        hapticNotificationGenerator?.prepare()
        
        do {
            try moc.save()
            hapticNotificationGenerator?.notificationOccurred(.success)
        } catch {
            print(error.localizedDescription)
            hapticNotificationGenerator?.notificationOccurred(.error)
        }
        loadData()
        hapticNotificationGenerator = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let taskDetailVC = segue.destination as? TaskDetailsViewController {
            taskDetailVC.hidesBottomBarWhenPushed = true
            taskDetailVC.delegate = self
            taskDetailVC.task = sender as? Task
        }
    }
    fileprivate func showOnboardingIfNeeded() {
        guard let onboardingController = self.storyboard?.instantiateViewController(identifier: Constants.ViewController.Onboarding) as? OnboardingViewController else { return }
        
        if !onboardingController.alreadyShown() {
            DispatchQueue.main.async {
                self.present(onboardingController, animated: true)
            }
        }
    }
    fileprivate func setupSearchController() {
        resultsTableController =
            self.storyboard?.instantiateViewController(withIdentifier: Constants.ViewController.ResultsTable) as? ResultsTableController
        resultsTableController.tableView.delegate = self
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.view.backgroundColor = .white
    }
    
    fileprivate func setupEmptyState() {
        let emptyBackgroundView = EmptyState(.emptyList)
        tableView.backgroundView = emptyBackgroundView
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.sortButton.isEnabled = self.todoList.count > 0
        
        if todoList.isEmpty {
            tableView.separatorStyle = .none
            tableView.backgroundView?.isHidden = false
        } else {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView?.isHidden = true
            
        }
        
        return todoList.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cell.taskCell, for: indexPath) as! TaskCell
        let task = todoList[indexPath.row]
        cell.title.text = task.title
        cell.subtitle.text = task.dueDate
        cell.starImage.isHidden = todoList[indexPath.row].isFavourite ? false : true
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastIndexTapped = indexPath.row
        let task = todoList[indexPath.row]
        performSegue(withIdentifier: Constants.Segue.taskToTaskDetail, sender: task)
    }
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let actions = Constants.Action.self
        let delete = UIContextualAction(style: .destructive, title: actions.delete) { _,_,_ in
            self.deleteTask(at: indexPath.row)
        }
        let star = UIContextualAction(style: .normal, title: .empty) { _,_,_ in
            self.starTask(at: indexPath.row)
        }
        star.backgroundColor = .orange
        star.title = todoList[indexPath.row].isFavourite ? actions.unstar : actions.star
        
        let swipeActions = UISwipeActionsConfiguration(actions: [delete,star])
        return swipeActions
    }
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let completeTask = UIContextualAction(style: .normal, title: .empty) {  (_, _, _) in
            self.completeTask(at: indexPath.row)
        }
        completeTask.backgroundColor = .systemGreen
        completeTask.title = Constants.Action.complete
        let swipeActions = UISwipeActionsConfiguration(actions: [completeTask])
        
        return swipeActions
    }
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension TodoViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            break
        @unknown default:
            break
        }
    }
}
extension TodoViewController : TaskDelegate{
    func didTapSave(task: Task) {
        todoList.append(task)
        do {
            try moc.save()
        } catch {
            todoList.removeLast()
            print(error.localizedDescription)
        }
        loadData()
    }
    
    func didTapUpdate(task: Task) {
        updateTask()
    }
    
    
}

extension TodoViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if let text: String = searchController.searchBar.text?.lowercased(), text.count > 0, let resultsController = searchController.searchResultsController as? ResultsTableController {
            resultsController.todoList = todoList.filter({ (task) -> Bool in
                if task.title?.lowercased().contains(text) == true || task.subTasks?.lowercased().contains(text) == true {
                    return true
                }
                return false
            })
            let fetchRequest : NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "title contains[c] %@", text)
            setupFetchedResultsController(fetchRequest: fetchRequest)
            resultsController.tableView.reloadData()
        } else {
            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.reloadData()
    }
}
extension TodoViewController {
    
    func showSortAlertController() {
        let alertController = UIAlertController(title: nil, message: "Choose sort type", preferredStyle: .actionSheet)
        
        SortTypesAvailable.allCases.forEach { (sortType) in
            let action = UIAlertAction(title: sortType.getTitleForSortType(), style: .default) { (_) in
                self.currentSelectedSortType = sortType
                self.loadData()
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: Constants.Action.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
}
