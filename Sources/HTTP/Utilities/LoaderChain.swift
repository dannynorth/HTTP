internal actor LoaderChain {
    
    static let shared = LoaderChain()
    
    private init() { }
    
    // BUG: this will retain loaders indefinitely
    private var chain = Dictionary<ObjectIdentifier, HTTPLoader>()
    
    func nextLoader(for loader: HTTPLoader) -> HTTPLoader? {
        let id = ObjectIdentifier(loader)
        return chain[id]
    }
    
    func setNextLoader(_ next: HTTPLoader?, for loader: HTTPLoader) {
        let id = ObjectIdentifier(loader)
        
        if let n = next {
            
            let cycleDetection = sequence(first: loader, next: { l -> HTTPLoader? in
                let loaderID = ObjectIdentifier(l)
                return self.chain[loaderID]
            })
            
            for next in cycleDetection {
                if next === n { fatalError("Cycle detected while setting the nextLoader") }
            }
            
            chain[id] = n
            
        } else {
            chain.removeValue(forKey: id)
        }
    }
    
}
