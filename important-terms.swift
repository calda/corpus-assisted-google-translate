//
//  important-terms.swift
//  Translate
//
//  Created by Cal Stephens on 4/14/19.
//  Copyright © 2019 Cal Stephens. All rights reserved.
//

import Foundation


/// find the terms of above-average importance in the reference corpus
/// than have are underrepresented in the machine translated corpous
func importantTerms(
    in referenceCorpus: [StringsEntry],
    comparedTo machineTranslatedCorpus: [StringsEntry],
    minimumCountInReferenceCorpus: Int = 5,
    standardDeviationsFromMean: Double = 0.75) -> [(term: String, importanceScore: Double)]
{
    let referenceTranslationsDocument = contiguousDocument(from: referenceCorpus).lowercased()
    let machineTranslatedDocument = contiguousDocument(from: machineTranslatedCorpus).lowercased()
    
    let uniqueTermsInReferenceCorpus = Array(Set<String>([
        referenceTranslationsDocument.unigrams,
        referenceTranslationsDocument.bigrams,
        referenceTranslationsDocument.trigrams,
        referenceTranslationsDocument.ngrams(n: 4)
    ].flatMap { $0 }))
    // filter out template terms like `%@` and `%1$@`,
    // because trying to patch issues with those will almost certainly break the string templates
    .filter { !$0.contains("%") }
    // Make sure the longest word in the term is atleast three leters.
    //
    // This helps eliminate stop words that get used in the reference translation
    // but not the machine translation. It's more likely that trying to hack these in
    // would munge the sentences than actually increase their legibility.
    .filter { ($0.words.map { $0.count }.max() ?? 0) > 3 }
    
    
    let termFrequencies = uniqueTermsInReferenceCorpus.map { (term: String) ->
        (term: String,
        totalCount: Int,
        referenceTermFrequency: Double,
        machineTranslatedTermFrequency: Double,
        frequencyRatio: Double) in
        
        let totalCount = (referenceTranslationsDocument + " " + machineTranslatedDocument).count(of: term)
        let referenceTermFrequency = termFrequency(of: term, in: referenceTranslationsDocument)
        let machineTranslatedTermFrequency = termFrequency(of: term, in: machineTranslatedDocument)
        let frequencyRatio = referenceTermFrequency / machineTranslatedTermFrequency
        
        return (term, totalCount, referenceTermFrequency, machineTranslatedTermFrequency, frequencyRatio)
    }
    
    // calculate the cap for being of "above-average importance"
    // (let's say some number of standard deviations above the norm)
    let ratios = termFrequencies.map { $0.frequencyRatio }.filter { $0.isFinite }
    let minimumFrequenctRatio = ratios.average() + (ratios.standardDeviation() * standardDeviationsFromMean)
    
    let importantTerms = termFrequencies.filter {
        $0.frequencyRatio > minimumFrequenctRatio
            && $0.term.count > 2
            && $0.totalCount > minimumCountInReferenceCorpus
        }.map { (
            term: $0.term,
            importanceScore: pow($0.frequencyRatio, 2) * Double($0.term.count) * pow(Double($0.totalCount), 2))
        }.sorted { $0.importanceScore > $1.importanceScore }
    
    return importantTerms
}


/// Finds terms that occur disproportionately frequently
/// in machine translations of references phrases that do contain the term.
/// These terms are good potential mappings that could be swapped out
func possibleMappings(
    for term: String,
    in referenceCorpus: [StringsEntry],
    comparedTo machineTranslatedCorpus: [StringsEntry])
    -> (term: String, possibleMappingsForTerm: [String])?
{
    
    var translationsExpectedToHaveTerm = [StringsEntry]()
    var translationsExpectedToNotHaveTerm = [StringsEntry]()
    
    for (referenceEntry, machineTranslatedEntry) in zip(referenceCorpus, machineTranslatedCorpus) {
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

    var translationTargets = importantTerms(
        in: translationsExpectedToHaveTerm,
        comparedTo: translationsExpectedToNotHaveTerm,
        minimumCountInReferenceCorpus: translationsExpectedToHaveTerm.count / 4,
        standardDeviationsFromMean: 0)
        .map { $0.term }
    
    if translationTargets.count == 0 {
        return nil
    }
    
    // take the 4 most likely possible translation targets,
    // plus the longest common substring of those targets
    translationTargets = Array(translationTargets[..<min(translationTargets.count, 4)])
    translationTargets += [LongestCommon.substringOf(translationTargets).trimmingCharacters(in: .whitespaces)]
    
    return (
        term: term,
        possibleMappingsForTerm: translationTargets
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
}
