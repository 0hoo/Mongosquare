public struct DocumentSlice: RandomAccessCollection {
    public func index(before i: DocumentIndex) -> DocumentIndex {
        return DocumentIndex(offset: i.offset - 1)
    }
    
    public func index(after i: DocumentIndex) -> DocumentIndex {
        return DocumentIndex(offset: i.offset + 1)
    }
    
    public subscript(position: DocumentIndex) -> (String, Primitive) {
        return document.pair(atIndex: position)!
    }
    
    public typealias Element = (String, Primitive)
    public typealias SubSequence = DocumentSlice
    
    let document: Document
    public let startIndex: DocumentIndex
    public let endIndex: DocumentIndex
}

public struct DocumentIterator: IteratorProtocol {
    let document: Document
    let count: Int
    var index: DocumentIndex
    
    init(document: Document) {
        self.document = document
        self.count = document.count
        self.index = document.startIndex
    }
    
    public mutating func next() -> (String, Primitive)? {
        let pair = document.pair(atIndex: index)
        index.offset += 1
        return pair
    }
}

extension Document {
    func pair(atIndex index: DocumentIndex) -> (String, Primitive)? {
        guard index.offset < count else { return nil }

        return (keys[index.offset], values[index.offset])
    }
}
