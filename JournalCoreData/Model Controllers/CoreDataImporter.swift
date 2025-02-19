//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                let entry = self.fetchEntriesFromPersistentStore(with: identifier, in: self.context)
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            self.timeChecker()
            completion(nil)
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    private func fetchEntriesFromPersistentStore(entries: [EntryRepresentation], context: NSManagedObjectContext) -> [String : Entry] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let identifiers: [String] = entries.compactMap { $0.identifier }
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var result: [String : Entry]? = [:]
        let fetchedEntries = try context.fetch(fetchRequest)
        for entry in fetchedEntries {
            result?[entry.identifier!] = entry
        }
        catch {
            NSLog("Error fetching entries: \(error)")
            return result
        }
    }
    
    private func timeChecker() {
        let time = Date()
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "HH:mm:ss"
        print("Sync finished at: \(timeFormat.string(from: time))")
    }
    
    let context: NSManagedObjectContext
}
