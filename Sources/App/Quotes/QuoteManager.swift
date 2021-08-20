/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Vapor

class QuoteManager {
  let apiKey = "OfDlMQJ5IlftJqpD5xPStDZD4"
  let apiSecret = "FqPk2lqCyRV0ms6qAiZfKFdCTQEVXqx4sEFmU5dnMBpMe47xBq"
  let accessToken = "1347672661200048133-6dNZxEeaRiptUkv4aGQ7XgOoNtyeDS"
  let accessSecret = "X3uMVLvX9MDA95NeWTraQ5vYLFFvL8jGWHGwvvLKAfs43"

  let tweetURI = URI(string: "https://api.twitter.com/1.1/statuses/update.json")

  static let shared = QuoteManager()
  var quoteBucket = Quotes.steveJobs

  @discardableResult
  func tweetQuote(with client: Client) -> EventLoopFuture<ClientResponse> {
    let nonce = UUID().uuidString
    let timestamp = String(Int64(Date().timeIntervalSince1970))
    let quote = nextQuote()

    let signature = oauthSignature(nonce: nonce, timestamp: timestamp, quote: quote)
    let oAuthHeaders = headers(nonce: nonce, timestamp: timestamp, signature: signature)
    let tweetURI = URI(string: tweetURI.string.appending("?status=\(quote.urlEncodedString())"))

    return client.post(tweetURI, headers: oAuthHeaders)
  }

  func nextQuote() -> String {
    if quoteBucket.isEmpty {
      quoteBucket = Quotes.steveJobs
    }
    return quoteBucket.removeFirst()
  }

  func oauthSignature(nonce: String, timestamp: String, quote: String) -> String {
    let oauthParameters: [String: String] = [
      "oauth_consumer_key": apiKey,
      "oauth_nonce": nonce,
      "oauth_signature_method": "HMAC-SHA1",
      "oauth_timestamp": timestamp,
      "oauth_token": accessToken,
      "oauth_version": "1.0",
      "status": quote
    ]

    return oauthParameters.signature(httpMethod: "POST", url: tweetURI.string, apiKey: apiSecret, secret: accessSecret)
  }

  func headers(nonce: String, timestamp: String, signature: String) -> HTTPHeaders {
    return [
      "oauth_consumer_key": apiKey,
      "oauth_signature_method": "HMAC-SHA1",
      "oauth_timestamp": timestamp,
      "oauth_token": accessToken,
      "oauth_version": "1.0",
      "oauth_nonce": nonce,
      "oauth_signature": signature
    ]
      .oauthHeader()
  }
}
