import Foundation
import ARKit

// MARK: - This extension adds two different features to the String class, which will be key in order to sort out different nodes depending on the carachters their descriptions contain. Hence a contains() and a containsIgnoringCase() functions are added to the initial functionality. 
extension String {
    
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
}

