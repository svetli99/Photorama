
import UIKit
import CoreData

class TagsViewController: UITableViewController {
    var store = PhotoStore.shared
    var photo: Photo!
    var selectedIndexRows = Set<Int>()
    
    let tagDataSource = TagDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = tagDataSource
        tableView.delegate = self
        store.tagDataSource = tagDataSource
        updateTags()
    }
    
    private func updateTags() {
        store.fetchAllTags { tagsResult in
            do {
                let tags = try tagsResult.get()
                self.tagDataSource.tags = tags
                guard let photoTags = self.photo.tags as? Set<Tag> else {
                    return
                }
                
                for tag in photoTags {
                    if let index = self.tagDataSource.tags.firstIndex(of: tag) {
                        self.selectedIndexRows.insert(index)
                    }
                }
            } catch {
                print("Error fetching tags: \(error).")
            }
            
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tag = tagDataSource.tags[indexPath.row]
        
        if selectedIndexRows.contains(indexPath.row) {
            selectedIndexRows.remove(indexPath.row)
            photo.removeFromTags(tag)
        } else {
            selectedIndexRows.insert(indexPath.row)
            photo.addToTags(tag)
        }
        
        do {
            try store.persistentContainer.viewContext.save()
        } catch {
            print("Core Data save failed: \(error).")
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.accessoryType = selectedIndexRows.contains(indexPath.row) ? .checkmark : .none
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func addNewTag(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add Tag", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "tag name"
            textField.autocapitalizationType = .words
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            if let tagName = alertController.textFields?.first?.text {
                let context = self.store.persistentContainer.viewContext
                let newTag = Tag(context: context)
                newTag.setValue(tagName, forKey: "name")
                
                do {
                    try context.save()
                } catch {
                    print("Core Data save failed: \(error).")
                }
                self.tagDataSource.apendingTag(newTag)
                self.tableView.reloadData()
            }
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}
