#!/usr/bin/swift

import Foundation


let stringsFileName = "Window Spanish Translations.strings"
let destinationLanguage = "es"


guard let inputStrings = readStringsFile(stringsFileName) else {
    fatalError("Could not read Strings file \(stringsFileName)")
}

// the compiler gets freaked out by the above^ line for some reason,
// so redeclare this here.
let referenceCorpus: [StringsEntry] = inputStrings

let machineTranslatedCorpus = loadCloudTranslatedStrings(
    for: referenceCorpus,
    in: stringsFileName,
    to: destinationLanguage)


let defaultBLEUScore = bleuScore(
    referenceCorpus: referenceCorpus,
    machineTranslatedCorpus: machineTranslatedCorpus)

print("Original BLEU score: \(defaultBLEUScore)")


// Identify the important terms in the reference corpus
// that occur infrequently in the machine translated corpus.

let importantTermsInReferenceCorpus = importantTerms(
    in: referenceCorpus,
    comparedTo: machineTranslatedCorpus)
    .map { $0.term }

print("\nIdentified \(importantTermsInReferenceCorpus.count) terms that appear significantly more frequently in the reference translations:\n\(importantTermsInReferenceCorpus)\n")


// generate possible mappings from the Machine Translated corpus to the Reference Corpus

let mappings = importantTermsInReferenceCorpus.compactMap { term in
    return possibleTranslationTargets(
        for: term,
        in: referenceCorpus,
        comparedTo: machineTranslatedCorpus)
}

print(mappings)


