//
//  String+Extensions.swift
//  ARSynthesis
//
//  Created by Pol Piella on 05/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import Foundation
import ARKit
extension String {
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
}

