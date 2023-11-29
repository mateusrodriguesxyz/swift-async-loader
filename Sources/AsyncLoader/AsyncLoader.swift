import Foundation

public enum AsyncLoaderState<Value> {
    case loading(Task<Value?, Never>)
    case loaded(Value, date: Date)
}

public enum AsyncLoaderValueCaching {
    case enabled
    case disabled
}

public protocol AsyncLoader: Actor {
    associatedtype Value
    associatedtype ID: Hashable
    var values: [ID: AsyncLoaderState<Value>] { get set }
    func task(for id: ID) -> Task<Value?, Never>
    func data(from value: Value) -> Data?
    func value(from data: Data) -> Value?
}

extension AsyncLoader {
    
    func cancel(for id: ID) {
        if case let .loading(task) = values[id] {
            task.cancel()
        }
    }
    
    public func value(for id: ID, caching: AsyncLoaderValueCaching = .enabled, modificationDate: Date? = nil) async -> Value? {
        
        let task: Task<Value?, Never>
                
        if let state = values[id] {
            switch state {
                case .loaded(let value, let date):
                    if let modificationDate, date < modificationDate {
                        task = self.task(for: id)
                        values[id] = .loading(task)
                    } else {
                        return value
                    }
                case .loading(let taskInProgress):
                    task = taskInProgress
            }
        } else {
            
            if caching == .enabled {
                if let cachedValue = await cachedValue(for: id, modificationDate: modificationDate) {
                    values[id] = .loaded(cachedValue, date: .now)
                    return cachedValue
                }
            }
            
            task = self.task(for: id)
            values[id] = .loading(task)
        }
        
        let value = await task.value
                
        if let value = value {
            if caching == .enabled {
                cache(value, for: id)
            }
            values[id] = .loaded(value, date: .now)
        } else {
            values[id] = nil
        }
        
        return value
        
    }
    
    func cachedValue(for id: ID, modificationDate: Date?) async -> Value? {
            
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        
        let url = caches.appendingPathComponent("\(id)")
                
        if let modificationDate {
            
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) as [FileAttributeKey: Any] else { return nil }
            
            if let creationDate = attributes[.creationDate] as? Date, creationDate >= modificationDate {
                if let data = try? Data(contentsOf: url) {
                    return value(from: data)
                }
            }
            
        } else {
            if let data = try? Data(contentsOf: url) {
                return value(from: data)
            }
        }
        
        return nil
        
    }
    
    func cache(_ value: Value, for id: ID) {
           
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        
        let url = caches.appendingPathComponent("\(id)")
        
        if let data = data(from: value) {
            try? data.write(to: url)
        }
        
    }
    
    public func removeLoadedValue(for id: ID) {
        values[id] = nil
    }
    
    public func removeCachedValue(for id: ID) {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let url = caches.appendingPathComponent("\(id)")
        try? FileManager.default.removeItem(at: url)
    }
    
}
