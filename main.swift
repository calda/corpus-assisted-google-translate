#!/usr/bin/swift

import Foundation


let stringsFileName = "Window Spanish Translations.strings"
let destinationLanguage = "es"


guard let strings = readStringsFile(stringsFileName) else {
    fatalError("Could not read Strings file \(stringsFileName)")
}


// Translate the strings to the destination language using Google Cloud Translate
// .. or use the cached `-cloud-translations` file if it exists.

let cloudTranslatedStrings: [StringsEntry]
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
    
    cloudTranslatedStrings = cloudTranslate(strings, to: destinationLanguage, apiKey: apiKey)
    
    writeStringsFile(cloudTranslatedStringsFileName, with: cloudTranslatedStrings)
    print("Automatically cloud-translated \(cloudTranslatedStrings.count) strings to \(destinationLanguage)")
}


print(bleuScore(
    referenceCorpus: strings,
    machineTranslatedCorpus: cloudTranslatedStrings))


