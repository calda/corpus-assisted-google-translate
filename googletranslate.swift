import Foundation

// Uses Google's Cloud Translation API to translate a .strings file


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
    return cloudTranslatedStrings
}
