//
//  utils.swift
//  Translate
//
//  Created by Cal Stephens on 4/14/19.
//  Copyright © 2019 Cal Stephens. All rights reserved.
//

import Foundation

func readFile(_ fileName: String, using encoding: String.Encoding) -> String {
    guard let textContent = readFileIfPresent(fileName, using: encoding) else {
        fatalError("Could not read file \(fileName).")
    }
    
    return textContent
}

func readFileIfPresent(_ fileName: String, using encoding: String.Encoding) -> String? {
    let url = URL(fileURLWithPath: "\(FileManager.default.currentDirectoryPath)/\(fileName)")
    
    guard let data = try? Data(contentsOf: url),
        let textContent = String(data: data, encoding: encoding) else
    {
        return nil
    }
    
    return textContent
}
