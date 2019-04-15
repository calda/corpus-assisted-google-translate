//
//  important-terms.swift
//  Translate
//
//  Created by Cal Stephens on 4/14/19.
//  Copyright © 2019 Cal Stephens. All rights reserved.
//

/// find the terms of above-average importance in the reference corpus
/// than have are underrepresented in the machine translated corpous
func importantTerms(
    in referenceCorpus: [StringsEntry],
    comparedTo machineTranslatedCorpus: [StringsEntry],
    minimumCountInReferenceCorpus: Int = 5,
    standardDeviationsFromMean: Double = 0.75) -> [(term: String, importanceScore: Double)]
{
    let referenceTranslationsDocument = contiguousDocument(from: referenceCorpus).lowercased()
    let machineTranslatedDocument = contiguousDocument(from: cloudTranslatedStrings).lowercased()
    
    let uniqueTermsInReferenceCorpus = Array(Set<String>([
        referenceTranslationsDocument.unigrams,
        referenceTranslationsDocument.bigrams,
        referenceTranslationsDocument.trigrams,
        referenceTranslationsDocument.ngrams(n: 4)
    ].flatMap { $0 }))
    
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
        }.map { (term: $0.term, importanceScore: $0.frequencyRatio * Double($0.term.count) * Double($0.totalCount)) }
        .sorted { $0.importanceScore < $1.importanceScore }
    
    return importantTerms
}
