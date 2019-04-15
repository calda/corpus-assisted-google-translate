import Foundation

// an implementation of the tf-idf (term frequency — inverse document frequency) algorithm
// http://www.tfidf.com

func termFrequency(of term: String, in document: String) -> Double {
    let numberOfAppearencesInDocument = Double(document.count(of: term))
    let totalTermsInDocument = floor(Double(document.words.count) / Double(term.words.count))
    return numberOfAppearencesInDocument / totalTermsInDocument
}

func inverseDocumentFrequency(of term: String, allDocuments: [String]) -> Double {
    let totalNumberOfDocuments = Double(allDocuments.count)
    let numberOfDocumentsWithTerm = Double(allDocuments.filter { $0.contains(term) }.count)
    return log(totalNumberOfDocuments / numberOfDocumentsWithTerm)
}

func tfidf(of term: String, in document: String, allDocuments: [String]) -> Double {
    return termFrequency(of: term, in: document) * inverseDocumentFrequency(of: term, allDocuments: allDocuments)
}


func contiguousDocument(from entries: [StringsEntry]) -> String {
    return entries.compactMap { entry -> String? in
        guard let translation = entry.translatedText else {
            return nil
        }
        
        // strip out punctuation that isn't meaningful on the word-level
        return translation.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "¿", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "¡", with: "")
    }.joined(separator: " ")
}


extension String {
    
    func count(of stringToFind: String) -> Int {
        var stringToSearch = self
        var count = 0
        while let foundRange = stringToSearch.range(of: stringToFind, options: [.diacriticInsensitive]) {
            stringToSearch = stringToSearch.replacingCharacters(in: foundRange, with: "")
            count += 1
        }
        return count
    }
}
