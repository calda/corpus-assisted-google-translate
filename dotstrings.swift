import Foundation

// A collection of utils for reading and writing .strings files
//
// Usage:
// let strings = readStringsFile("Window Spanish Translations.strings")
// writeStringsFile("Google Translations.strings", with: strings)


struct StringsEntry {
    var originalText: String
    var translatedText: String?
    var comments: [String]
}


func readStringsFile(_ name: String) -> [StringsEntry]? {
    guard let textContent = readFileIfPresent(name, using: .utf8) else {
        return nil
    }
    
    var entries = [StringsEntry]()
    var commentsForInProgressEntry = [String]()
    
    for line in textContent.components(separatedBy: "\n") {
        let cleanedLine = line
            .replacingOccurrences(of: "/*", with: "")
            .replacingOccurrences(of: "*/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // if this is a `"original" = "translation";` line, finalize the entry
        if cleanedLine.contains(" = ") && cleanedLine.hasSuffix(";") {
            let items = cleanedLine
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: ";", with: "")
                .components(separatedBy: "=")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            guard let originalText = items.first, !originalText.isEmpty else {
                continue
            }
            
            var translatedText = items.last
            if translatedText?.isEmpty == true {
                translatedText = nil
            }
            
            entries.append(StringsEntry(
                originalText: originalText,
                translatedText: translatedText,
                comments: commentsForInProgressEntry))
            
            commentsForInProgressEntry = []
            
        }
        
        // otherwise, consume the line as a comment
        else if !cleanedLine.isEmpty {
            commentsForInProgressEntry.append(cleanedLine)
        }
    }
    
    return entries
}


func writeStringsFile(_ name: String, with contents: [StringsEntry]) {
    let textContent = contents.map { entry in
        #"""
        /* \#(entry.comments.joined(separator: "\n   ")) */
        "\#(entry.originalText)" = "\#(entry.translatedText ?? "")";
        """#
    }.joined(separator: "\n\n")
    
    let url = URL(fileURLWithPath: "\(FileManager.default.currentDirectoryPath)/\(name)")
    try! textContent.data(using: .utf16)!.write(to: url)
}
