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
            let currencyRates = result.map { Currency(baseCurrency: $0.baseCurrency ?? "", currency: $0.currency ?? "", saleRateNB: $0.saleRateNB , purchaseRateNB: $0.purchaseRateNB, saleRate: $0.saleRate , purchaseRate: $0.purchaseRate , timestamp: $0.timestamp ?? String()) }
            return currencyRates
        } catch let error as NSError {
            print("Failed to fetch currency rates: \(error)")
            return []
        }
    }
    
    func saveCurrencyRate(baseCurrencyCode: String, currencyCode: String, buyRate: Double?, sellRate: Double?, timestamp: String) {
        guard let buyRate = buyRate, let sellRate = sellRate else {
            print("No buy or sell rate for \(currencyCode), not saving this currency.")
            return
        }
        
        if let entity = NSEntityDescription.entity(forEntityName: "CurrencyRate", in: context) {
            let currencyRate = NSManagedObject(entity: entity, insertInto: context)
            
            currencyRate.setValue(baseCurrencyCode, forKey: "baseCurrency")
            currencyRate.setValue(currencyCode, forKey: "currency")
            currencyRate.setValue(sellRate, forKey: "saleRate")
            currencyRate.setValue(buyRate, forKey: "purchaseRate")
            currencyRate.setValue(timestamp, forKey: "timestamp")
            
            do {
                try context.save()
                print("Currency rate saved successfully (CurrencyRepository)")
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
            print("All currency rates deleted successfully (CurrencyRepository)")
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
    
    func getLastUpdateTimestamp() -> String? {
        let fetchRequest: NSFetchRequest<CurrencyRate> = CurrencyRate.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try context.fetch(fetchRequest)
            let lastCurrencyRate = result.first
            let timestamp = lastCurrencyRate?.timestamp
            return timestamp
        } catch let error as NSError {
            print("Failed to fetch last update timestamp: \(error)")
            return nil
        }
    }
    
    func shouldFetchCurrencyRates() -> Bool {
        guard let lastUpdateTimestamp = getLastUpdateTimestamp() else {
            return true
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy h:mm a"
        
        guard let lastUpdateDate = dateFormatter.date(from: lastUpdateTimestamp) else {
            return true
        }
        
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(lastUpdateDate)
        let hoursPassed = timeInterval / 3600
        let updateThreshold: TimeInterval = 1
        return hoursPassed >= updateThreshold
    }
}
