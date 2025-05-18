//
//  ThreadSafeDictionary.swift
//
//  Created by Shashank on 29/10/20.
//
import Foundation

class ThreadSafeDictionary<V: Hashable,T>: Collection {

    private var dictionary: [V: T]
    private let concurrentQueue = DispatchQueue(label: "com.bn2002.picsum.dictQueue", attributes: .concurrent)

    var keys: Dictionary<V, T>.Keys {
        self.concurrentQueue.sync {
            return self.dictionary.keys
        }
    }

    var values: Dictionary<V, T>.Values {
        self.concurrentQueue.sync {
            return self.dictionary.values
        }
    }

    var startIndex: Dictionary<V, T>.Index {
        self.concurrentQueue.sync {
            return self.dictionary.startIndex
        }
    }

    var endIndex: Dictionary<V, T>.Index {
        self.concurrentQueue.sync {
            return self.dictionary.endIndex
        }
    }

    init(dict: [V: T] = [V:T]()) {
        self.dictionary = dict
    }

    func index(after i: Dictionary<V, T>.Index) -> Dictionary<V, T>.Index {
        self.concurrentQueue.sync {
            return self.dictionary.index(after: i)
        }
    }
    
    subscript(key: V) -> T? {
        set(newValue) {
            self.concurrentQueue.async(flags: .barrier) { [weak self] in
                self?.dictionary[key] = newValue
            }
        }
        get {
            self.concurrentQueue.sync {
                return self.dictionary[key]
            }
        }
    }

    subscript(index: Dictionary<V, T>.Index) -> Dictionary<V, T>.Element {
        self.concurrentQueue.sync {
            return self.dictionary[index]
        }
    }
    
    func removeValue(forKey key: V) {
        self.concurrentQueue.async(flags: .barrier) {[weak self] in
            self?.dictionary.removeValue(forKey: key)
        }
    }

    func removeAll() {
        self.concurrentQueue.async(flags: .barrier) {[weak self] in
            self?.dictionary.removeAll()
        }
    }

}
