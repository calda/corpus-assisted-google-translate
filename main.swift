#!/usr/bin/swift

import Foundation


let stringsFileName = "Window Spanish Translations.strings"
let destinationLanguage = "es"


guard let inputStrings = readStringsFile(stringsFileName) else {
    fatalError("Could not read Strings file \(stringsFileName)")
}

// the compiler gets freaked out by the above^ line for some reason,
// so redeclare this here.
var referenceCorpus: [StringsEntry] = inputStrings

var machineTranslatedCorpus = loadCloudTranslatedStrings(
    for: referenceCorpus,
    in: stringsFileName,
    to: destinationLanguage)

// shuffle the corpuses by zipping them together
let shuffledCorpuses = zip(referenceCorpus, machineTranslatedCorpus).shuffled()
referenceCorpus = shuffledCorpuses.map { $0.0 }
machineTranslatedCorpus = shuffledCorpuses.map { $0.1 }


// separate the data into training and testing sets
let trainingRatio = 1.0

let referencePartitionIndex = Int(Double(referenceCorpus.count) * trainingRatio)
let trainingReferenceCorpus = Array(referenceCorpus[..<referencePartitionIndex])
let testingReferenceCorpus = Array(referenceCorpus[referencePartitionIndex...])

let machineTranslationsPartitionIndex = Int(Double(referenceCorpus.count) * trainingRatio)
let trainingMachineTranslationCorpus = Array(machineTranslatedCorpus[..<machineTranslationsPartitionIndex])
let testingMachineTranslationCorpus = Array(machineTranslatedCorpus[machineTranslationsPartitionIndex...])


// Identify the important terms in the reference corpus
// that occur infrequently in the machine translated corpus.
let importantTermsInReferenceCorpus = importantTerms(
    in: trainingReferenceCorpus,
    comparedTo: trainingMachineTranslationCorpus)
    .map { $0.term }

print("\nIdentified \(importantTermsInReferenceCorpus.count) terms that appear significantly more frequently in the reference translations:\n\(importantTermsInReferenceCorpus)\n")


// generate possible mappings from the Machine Translated corpus to the Reference Corpus
let mappings = importantTermsInReferenceCorpus.compactMap { term in
    return possibleMappings(
        for: term,
        in: trainingReferenceCorpus,
        comparedTo: trainingMachineTranslationCorpus)
}

print("Possible mappings:")
mappings.forEach { print("\($0.term) <= \($0.possibleMappingsForTerm)") }

print("\nStarting Genetic Algorithm to determine best mappings:")


// Use a Genetic Algorithm to determine the best set of mappings
let bestMappings = determineBestMappings(
    from: mappings,
    referenceCorpus: trainingReferenceCorpus,
    machineTranslatedCorpus: trainingMachineTranslationCorpus)

print("\nBest mappings:")
bestMappings.forEach { print("\($0.term) <= \($0.mapping)") }


// Save the Machine Translated Corpus with the best mappings applied
let outputFileName = stringsFileName
    .replacingOccurrences(of: ".strings", with: "-corpus-assisted-translations.strings")

writeStringsFile(outputFileName, with: applyMappings(bestMappings, to: machineTranslatedCorpus))
print("\nWrote \(outputFileName)")
