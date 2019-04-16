#!/usr/bin/swift

import Foundation


enum Mode {
    case crossValidation
    case learnAndApplyMappings
}


/// In an actual production tool these would be command-line arguments
let stringsFileName = "Window Spanish Translations.strings"
let destinationLanguage = "es"
let mode = Mode.learnAndApplyMappings


// load the strings
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

func trainBestMappings(
    referenceCorpus: [StringsEntry],
    machineTranslatedCorpus: [StringsEntry],
    testingTrainingRatio: Double,
    verbose: Bool = true,
    geneticAlgorithmGenerations: Int = 100)
    -> (mappings: [(term: String, mapping: String)],
        trainingCorpusBleuScore: Double,
        testingCorpusBleuScore: Double,
        googleTranslateUnadjustedBleuScore: Double)
{
    // shuffle the corpuses by zipping them together
    let shuffledCorpuses = zip(referenceCorpus, machineTranslatedCorpus).shuffled()
    let shuffledReferenceCorpus = shuffledCorpuses.map { $0.0 }
    let shuffledMachineTranslations = shuffledCorpuses.map { $0.1 }
    
    // separate the data into training and testing sets
    let referencePartitionIndex = Int(Double(shuffledReferenceCorpus.count) * testingTrainingRatio)
    let trainingReferenceCorpus = Array(shuffledReferenceCorpus.prefix(upTo: referencePartitionIndex))
    let testingReferenceCorpus = Array(shuffledReferenceCorpus.suffix(from: referencePartitionIndex))
    
    let machineTranslationsPartitionIndex = Int(Double(shuffledMachineTranslations.count) * testingTrainingRatio)
    let trainingMachineTranslations = Array(shuffledMachineTranslations.prefix(upTo: machineTranslationsPartitionIndex))
    let testingMachineTranslations = Array(shuffledMachineTranslations.suffix(from: machineTranslationsPartitionIndex))
    
    // Identify the important terms in the reference corpus
    // that occur infrequently in the machine translated corpus.
    let importantTermsInReferenceCorpus = importantTerms(
        in: trainingReferenceCorpus,
        comparedTo: trainingMachineTranslations)
        .map { $0.term }
    
    if verbose {
        print("\nIdentified \(importantTermsInReferenceCorpus.count) terms that appear significantly more frequently in the reference translations:\n\(importantTermsInReferenceCorpus)\n")
    }
    
    // generate possible mappings from the Machine Translated corpus to the Reference Corpus
    let mappings = importantTermsInReferenceCorpus.compactMap { term in
        possibleMappings(
            for: term,
            in: trainingReferenceCorpus,
            comparedTo: trainingMachineTranslations)
    }
    
    if verbose {
        print("Possible mappings:")
        mappings.forEach { print("\($0.term) <= \($0.possibleMappingsForTerm)") }
        
        print("\nStarting Genetic Algorithm to determine best mappings:")
    }
    
    // Use a Genetic Algorithm to determine the best set of mappings
    let bestMappings = determineBestMappings(
        from: mappings,
        referenceCorpus: trainingReferenceCorpus,
        machineTranslatedCorpus: trainingMachineTranslations,
        verbose: verbose,
        geneticAlgorithmGenerations: geneticAlgorithmGenerations)
    
    if verbose {
        print("\nBest mappings:")
        bestMappings.forEach { print("\($0.term) <= \($0.mapping)") }
    }
    
    return (
        mappings: bestMappings,
        
        trainingCorpusBleuScore: bleuScore(
            referenceCorpus: trainingReferenceCorpus,
            machineTranslatedCorpus: applyMappings(bestMappings, to: trainingMachineTranslations)),
        
        testingCorpusBleuScore: bleuScore(
            referenceCorpus: testingReferenceCorpus,
            machineTranslatedCorpus: applyMappings(bestMappings, to: testingMachineTranslations)),
    
        googleTranslateUnadjustedBleuScore: bleuScore(
            referenceCorpus: referenceCorpus,
            machineTranslatedCorpus: machineTranslatedCorpus)
    )
}


switch mode {
case .crossValidation:
    print("Training % \t Training Score \t Testing Score")
    
    // for every 10% from 0% to 100%,
    // take the average testing and training score of some number of runs
    for testingTrainingRatio in stride(from: 0.1, to: 1.1, by: 0.1) {
        let runCount = 10
        
        let runs = (1...runCount).map { run in
            trainBestMappings(
                referenceCorpus: referenceCorpus,
                machineTranslatedCorpus: machineTranslatedCorpus,
                testingTrainingRatio: testingTrainingRatio,
                verbose: false)
        }
        
        let averageTrainingScore = runs.map { $0.trainingCorpusBleuScore }.average()
        let averageTestingScore = runs.map { $0.testingCorpusBleuScore }.average()
        let averageUnadjustedScore = runs.map { $0.googleTranslateUnadjustedBleuScore }.average()
        print("\(testingTrainingRatio) \t \(averageTrainingScore) \t \(averageTestingScore) \t \(averageUnadjustedScore)")
    }
    
case .learnAndApplyMappings:
    
    let results = trainBestMappings(
        referenceCorpus: referenceCorpus,
        machineTranslatedCorpus: machineTranslatedCorpus,
        testingTrainingRatio: 1.0,
        geneticAlgorithmGenerations: 200)
    
    let bestMappings = results.mappings
    
    let fullCorpusBleuScore = bleuScore(
        referenceCorpus: referenceCorpus,
        machineTranslatedCorpus: applyMappings(bestMappings, to: machineTranslatedCorpus))
    
    print("Unadjusted Google Translate corpus BLEU score: \(results.googleTranslateUnadjustedBleuScore)")
    print("Training Corpus BLEU score with mappings applied: \(results.trainingCorpusBleuScore)")
    print("Testing Corpus BLEU score with mappings applied: \(results.testingCorpusBleuScore)")
    print("\nFull Corpus BLEU Score with mappings applied: \(fullCorpusBleuScore)")
    
    // Save the Machine Translated Corpus with the best mappings applied
    let outputFileName = stringsFileName
        .replacingOccurrences(of: ".strings", with: "-corpus-assisted-translations.strings")
    
    writeStringsFile(outputFileName, with: applyMappings(bestMappings, to: machineTranslatedCorpus))
    print("\nWrote \(outputFileName)")
    
}
