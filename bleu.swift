import Foundation

// an implementation of the BLEU (bilingual evaluation understudy) algorithm
// https://en.wikipedia.org/wiki/BLEU

func bleuScore(
    referenceTranslation: String,
    machineTranslation: String,
    ngramLength: Int = 4) -> Double
{
    // for short phrases, we have to cap the ngram length at the phrase length
    let ngramLengthToUse = min(min(ngramLength, machineTranslation.words.count), referenceTranslation.words.count)
    
    let referenceTranslationNgrams = referenceTranslation
        .lowercased()
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: ".", with: "")
        .ngrams(n: ngramLengthToUse)
    
    let machineTranslationNgrams = machineTranslation
        .lowercased()
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: ".", with: "")
        .ngrams(n: ngramLengthToUse)
    
    let recallSum = machineTranslationNgrams
        .map { referenceTranslationNgrams.contains($0) ? 1 : 0 }
        .reduce(0, +)
    
    return Double(recallSum) / Double(machineTranslationNgrams.count)
}

func bleuScore(
    referenceCorpus: [StringsEntry],
    machineTranslatedCorpus: [StringsEntry],
    ngramLength: Int = 4) -> Double
{
    let bleuScores = zip(referenceCorpus, machineTranslatedCorpus).map { referenceEntry, machineTranslatedEntry -> Double in
        guard referenceEntry.originalText == machineTranslatedEntry.originalText,
            let referenceTranslation = referenceEntry.translatedText,
            let machineTranslation = machineTranslatedEntry.translatedText else
        {
            fatalError("Mismatch between \(referenceEntry) and \(machineTranslatedEntry)")
        }
        
        return bleuScore(
            referenceTranslation: referenceTranslation,
            machineTranslation: machineTranslation,
            ngramLength: ngramLength)
    }
    
    // The BLEU algorithm calls for using the Geometric Mean,
    // but that doesn't work here because there are some strings with a 0.0 BLEU score (which kills the entire mean).
    //
    // let product = bleuScores.reduce(1, *)
    // return pow(product, 1 / Double(bleuScores.count))
    
    let sum = bleuScores.reduce(1, +)
    return sum / Double(bleuScores.count)
}


extension String {
    
    var words: [String] {
        return components(separatedBy: " ")
    }
    
    var unigrams: [String] {
        return ngrams(n: 1)
    }
    
    var bigrams: [String] {
        return ngrams(n: 2)
    }
    
    var trigrams: [String] {
        return ngrams(n: 3)
    }
    
    func ngrams(n: Int) -> [String] {
        let words = self.words
        
        if words.count < n {
            return []
        }
        
        var ngrams = [String]()
        
        for i in 0...(words.count - n) {
            ngrams.append(words[i...i+n-1].joined(separator: " "))
        }
        
        return ngrams
    }
    
}
