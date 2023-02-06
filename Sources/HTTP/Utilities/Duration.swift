import Foundation

extension Duration {
    
    init(_ timeInterval: TimeInterval) {
        let sec = floor(timeInterval)
        let rem = timeInterval - sec
        let atto = rem * 1_000_000_000_000_000_000
        
        self.init(secondsComponent: Int64(sec),
                  attosecondsComponent: Int64(atto))
    }
    
}
