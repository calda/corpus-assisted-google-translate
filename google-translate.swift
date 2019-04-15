import Foundation

// Uses Google's Cloud Translation API to translate a .strings file

/// Translate the strings to the destination language using Google Cloud Translate
/// .. or use the cached `-cloud-translations` file if it exists.
func loadCloudTranslatedStrings(
    for referenceStrings: [StringsEntry],
    in stringsFileName: String,
    to destinationLanguage: String)
    -> [StringsEntry]
{
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
    
    return cloudTranslatedStrings
}


func cloudTranslate(
    _ strings: [StringsEntry],
    to destinationLanguage: String,
    apiKey: String) -> [StringsEntry]
{
    print("Translating \(strings.count) strings to \(destinationLanguage) using Google Cloud Translate...")
    
    let batchTranslatedStrings = stride(from: 0, to: strings.count, by: 100).flatMap { rangeStart -> [StringsEntry] in
        let subset = strings[rangeStart ..< min(strings.count, rangeStart + 100)]
        
        return _cloudTranslate(
            upTo100Strings: [StringsEntry](subset),
            to: destinationLanguage,
            apiKey: apiKey)
    }
    
    guard batchTranslatedStrings.count == strings.count else {
        fatalError("Mismatch in input count and output count.")
    }
    
    return batchTranslatedStrings
    
}


private func _cloudTranslate(
    upTo100Strings: [StringsEntry],
    to destinationLanguage: String,
    apiKey: String) -> [StringsEntry]
{
    let semaphore = DispatchSemaphore(value: 0)
    
    var cloudTranslatedStrings: [StringsEntry]!
    
    let endpointUrl = URL(string: "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)")!
    var request = URLRequest(url: endpointUrl)
    request.httpMethod = "POST"
    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: [
        "type": "text",
        "source": "en",
        "target": destinationLanguage,
        "q": upTo100Strings.map { $0.originalText },
    ])
    
    URLSession.shared.dataTask(with: request) { responseData, request, error in
        guard let responseData = responseData,
            let jsonResponse = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
            let data = jsonResponse["data"] as? [String: Any],
            let translationDicts = data["translations"] as? [[String: Any]] else
        {
            fatalError("Could not communicate with Google Cloud Translate: \(String(describing: error))")
        }
        
        let cloudTranslations = translationDicts.map { $0["translatedText"] as? String }
        
        guard upTo100Strings.count == cloudTranslations.count else {
            fatalError("Mismatch between input strings count \(upTo100Strings.count) and translations returned from Google Cloud Translate (\(cloudTranslations.count))")
        }
        
        cloudTranslatedStrings = zip(upTo100Strings, cloudTranslations).map { originalStringsEntry, cloudTranslation in
            StringsEntry(
                originalText: originalStringsEntry.originalText,
                translatedText: cloudTranslation,
                comments: originalStringsEntry.comments)
        }
        
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    // Google Translate munges the %@ template syntax, so patch that in
    return cloudTranslatedStrings.map { entry in
        var mutableEntry = entry
        mutableEntry.translatedText = entry.translatedText?
            .replacingOccurrences(of: "% @", with: " %@")
            .replacingOccurrences(of: "% d", with: " %d")
            .replacingOccurrences(of: "% .01f", with: " %.01f")
            .replacingOccurrences(of: "% d", with: " %d")
            .replacingOccurrences(of: "% 1 $ @", with: " %1$@")
            .replacingOccurrences(of: "% 2 $ @", with: " %2$@")
            .replacingOccurrences(of: "% 3 $ @", with: " %3$@")
            .replacingOccurrences(of: "% 4 $ @", with: " %4$@")
            .replacingOccurrences(of: "% 5 $ @", with: " %5$@")
            .replacingOccurrences(of: " @", with: "%@")
            .trimmingCharacters(in: .whitespaces)
        return mutableEntry
    }
}
