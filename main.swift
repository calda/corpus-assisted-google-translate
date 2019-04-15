#!/usr/bin/swift

import Foundation


let stringsFileName = "Window Spanish Translations.strings"
let destinationLanguage = "es"


guard let referenceStrings = readStringsFile(stringsFileName) else {
    fatalError("Could not read Strings file \(stringsFileName)")
}


// Translate the strings to the destination language using Google Cloud Translate
// .. or use the cached `-cloud-translations` file if it exists.

var cloudTranslatedStrings: [StringsEntry]
let cloudTranslatedStringsFileName = stringsFileName.replacingOccurrences(
    of: ".strings",
    with: "-cloud-translations-\(destinationLanguage).strings")

if let existingCloudTranslatedStrings = readStringsFile(cloudTranslatedStringsFileName) {
    cloudTranslatedStrings = existingCloudTranslatedStrings
    print("Loaded \(cloudTranslatedStrings.count) existing \(destinationLanguage) cloud translations")
} else {
    guard let apiKey = readFileIfPresent("cloud-translate-api-key", using: .utf8) else {
        fatalError("Provide a `cloud-translate-api-key` file in the working directory.")
    }
    
    cloudTranslatedStrings = cloudTranslate(referenceStrings, to: destinationLanguage, apiKey: apiKey)
    
    writeStringsFile(cloudTranslatedStringsFileName, with: cloudTranslatedStrings)
    print("Automatically cloud-translated \(cloudTranslatedStrings.count) strings to \(destinationLanguage)")
}


let defaultBLEUScore = bleuScore(
    referenceCorpus: referenceStrings,
    machineTranslatedCorpus: cloudTranslatedStrings)

print("Original BLEU score: \(defaultBLEUScore)")



let importantTermsInReferenceCorpus = ["ventana de alimentación"]//importantTerms(in: referenceStrings, comparedTo: cloudTranslatedStrings)

print("\nIdentified \(importantTermsInReferenceCorpus.count) terms that appear significantly more frequently in the reference translations:\n\(importantTermsInReferenceCorpus)\n")


// Find the longest-common-cooccurring-subsequence for each of ther important terms

let mappings = importantTermsInReferenceCorpus.lazy.compactMap { term ->
    (term: String,
     translationsExpectedToHaveTerm: [String],
     importantTerms: [String])? in
    
    var translationsExpectedToHaveTerm = [StringsEntry]()
    var translationsExpectedToNotHaveTerm = [StringsEntry]()
    
    for (referenceEntry, machineTranslatedEntry) in zip(referenceStrings, cloudTranslatedStrings) {
        guard let referenceTranslation = referenceEntry.translatedText else {
            continue
        }
        
        if referenceTranslation.lowercased().contains(term.lowercased()) {
            if machineTranslatedEntry.translatedText?.lowercased().contains(term.lowercased()) == false {
                translationsExpectedToHaveTerm.append(machineTranslatedEntry)
            }
        } else {
            translationsExpectedToNotHaveTerm.append(machineTranslatedEntry)
        }
    }
    
    if translationsExpectedToHaveTerm.count == 0 {
        return nil
    }
    
    let possibleTranslationTargets = importantTerms(
            in: translationsExpectedToHaveTerm,
            comparedTo: translationsExpectedToNotHaveTerm,
            minimumCountInReferenceCorpus: translationsExpectedToHaveTerm.count / 4,
            standardDeviationsFromMean: 0)
    .map { term in
        return (term: term,
                count: translationsExpectedToHaveTerm.filter { ($0.translatedText ?? "").lowercased().contains(term.term.lowercased()) }.count)
    }
    
    // why is "ventana de comer" not in "importantTerms"????
    
    print(possibleTranslationTargets.sorted(by: { $0.count < $1.count  }))
    
    return (
        term: term,
        translationsExpectedToHaveTerm: translationsExpectedToHaveTerm.map { $0.translatedText ?? "" },
        importantTerms: possibleTranslationTargets.map { $0.term.term })
}

mappings.forEach { print($0); print("\n") }


