//
//  determine-best-mappings.swift
//  Translate
//
//  Created by Cal Stephens on 4/15/19.
//  Copyright © 2019 Cal Stephens. All rights reserved.
//

import Foundation


// uses a Genetic Algorithm to determine the best set of translation mappings

func determineBestMappings(
    from possibleMappings: [(term: String, possibleMappingsForTerm: [String])],
    referenceCorpus: [StringsEntry],
    machineTranslatedCorpus: [StringsEntry]) -> [(term: String, mapping: String)]
{
    GENETIC_ALGORITHM_DNA_SIZE = possibleMappings.count
    
    // the dna determines the index of each possible mapping to use
    func mappings(from dna: [Int]) -> [(term: String, mapping: String)] {
        return zip(dna, possibleMappings).compactMap { (dnaIndex, mappingEntry) in
            let (term, possibleMappingsForTerm) = mappingEntry
            
            if (dnaIndex - 1) < 0 || (dnaIndex - 1) >= possibleMappingsForTerm.count {
                return nil
            } else {
                return (term, possibleMappingsForTerm[dnaIndex - 1])
            }
        }
    }
    
    GENETIC_ALGORITHM_FITNESS_FUNCTION = { dna in
        let mappedCorpus = applyMappings(mappings(from: dna), to: machineTranslatedCorpus)
        
        let score = bleuScore(
            referenceCorpus: referenceCorpus,
            machineTranslatedCorpus: mappedCorpus)
        
        return score
    }
    
    return mappings(from: runGeneticAlgorithm())
}


func applyMappings(
    _ mappings: [(term: String, mapping: String)],
    to machineTranslatedCorpus: [StringsEntry]) -> [StringsEntry]
{
    return machineTranslatedCorpus.map { entry in
        entry.applyingMappings(mappings)
    }
}


extension StringsEntry {
    
    func applyingMappings(_ mappings: [(term: String, mapping: String)]) -> StringsEntry {
        guard var translation = translatedText else { return self }
        
        for (replacement, mapping) in mappings {
            if let rangeOfMapping = translation.lowercased().range(of: mapping.lowercased()) {
                translation = translation.lowercased().replacingCharacters(in: rangeOfMapping, with: replacement)
            }
        }
        
        return StringsEntry(
            originalText: self.originalText,
            translatedText: translation,
            comments: self.comments)
    }
    
}
