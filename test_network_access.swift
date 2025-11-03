#!/usr/bin/env swift

import Foundation

print("Testing network access...")

let url = URL(string: "https://www.google.com")!
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
        print("❌ Network Error: \(error.localizedDescription)")
        exit(1)
    }
    
    if let httpResponse = response as? HTTPURLResponse {
        print("✅ Network access works! Status: \(httpResponse.statusCode)")
        exit(0)
    }
}

task.resume()

// Keep the script running
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))
print("⏱️ Timeout - no response")
exit(1)
