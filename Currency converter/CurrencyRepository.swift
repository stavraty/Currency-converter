//
//  CurrencyRepository.swift
//  Currency converter
//
//  Created by AS on 18.05.2023.
//

import Foundation
import CoreData

class CurrencyRepository {
    
    private let persistentContainer: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        self.context = persistentContainer.viewContext
    }
    
    init(context: NSManagedObjectContext) {
        guard let coordinator = context.persistentStoreCoordinator else {
            fatalError("Persistent store coordinator not found.")
        }

        self.persistentContainer = NSPersistentContainer(name: "CurrencyDataModel")
        if let storeDescription = coordinator.persistentStores.first?.url {
            let persistentStoreDescription = NSPersistentStoreDescription(url: storeDescription)
            self.persistentContainer.persistentStoreDescriptions = [persistentStoreDescription]
        } else {
            fatalError("Persistent store description not found.")
        }
        self.persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        self.context = context
    }
    
    func getCurrencyRates() -> [Currency] {
        let fetchRequest: NSFetchRequest<CurrencyRate> = CurrencyRate.fetchRequest()
        do {
            let result = try context.fetch(fetchRequest)
            let currencyRates = result.map { Currency(ccy: $0.ccy ?? "", base_ccy: $0.base_ccy ?? "", buy: $0.buy ?? "", sale: $0.sale ?? "", timestamp: $0.timestamp ?? String()) }
            return currencyRates
        } catch let error as NSError {
            print("Failed to fetch currency rates: \(error)")
            return []
        }
    }
    
    func saveCurrencyRate(baseCurrencyCode: String, currencyCode: String, buyRate: String, sellRate: String, timestamp: String) {
        if let entity = NSEntityDescription.entity(forEntityName: "CurrencyRate", in: context) {
            let currencyRate = NSManagedObject(entity: entity, insertInto: context)
            
            currencyRate.setValue(baseCurrencyCode, forKey: "base_ccy")
            currencyRate.setValue(currencyCode, forKey: "ccy")
            currencyRate.setValue(buyRate, forKey: "buy")
            currencyRate.setValue(sellRate, forKey: "sale")
            currencyRate.setValue(timestamp, forKey: "timestamp")
            
            do {
                try context.save()
                print("Currency rate saved successfully")
            } catch let error as NSError {
                print("Failed to save currency rate: \(error)")
            }
        }
    }
    
    func deleteAllCurrencyRates() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CurrencyRate.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("All currency rates deleted successfully")
        } catch let error as NSError {
            print("Failed to delete all currency rates: \(error)")
        }
    }
    
    func fetchCurrencyRates() -> [CurrencyRate]? {
        let fetchRequest: NSFetchRequest<CurrencyRate> = CurrencyRate.fetchRequest()
        
        do {
            let currencyRates = try context.fetch(fetchRequest)
            return currencyRates
        } catch let error as NSError {
            print("Failed to fetch currency rates from Core Data: \(error)")
            return nil
        }
    }
}
