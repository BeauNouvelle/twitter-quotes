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
import CommonCrypto

extension Dictionary where Key == String, Value == String {
  /// Generates the `oauth_signature` based on the keys/values in this dictionary.
  func signature(httpMethod: String, url: String, apiKey: String, secret: String) -> String {
    let oauth = OAuth(httpMethod: httpMethod, url: url, oauthParameters: self)
    return oauth.signature(key: apiKey, secret: secret)
  }

  /// Generates an OAuth1.0 compliant header based on the keys/values in this dictionary.
  ///  - Note This function performs the appropriate URL encoding for each key/value stored.
  func oauthHeader() -> HTTPHeaders {
    var headerString = ""

    // The OAuth1.0 "Authorization" header requires multiple values formatted as a single string.
    for (key, value) in self {
      if !headerString.isEmpty {
        headerString.append(", ")
      }
      headerString.append(key.urlEncodedString())
      headerString.append("=")
      // Each value must be wrapped in quotes.
      headerString.append("\"")
      headerString.append(value.urlEncodedString())
      headerString.append("\"")
    }

    let headers: HTTPHeaders = ["Authorization": "OAuth \(headerString)"]
    return headers
  }
}

struct OAuth {
  private let methodOutput: String
  private let urlOutput: String
  private let parameterOutput: String

  internal init(httpMethod: String, url: String, oauthParameters: [String: String]) {
    methodOutput = httpMethod.uppercased()
    urlOutput = url.urlEncodedString()

    var oauthString: String = ""

    // Parameters must be sorted, urlEncoded, linked together with ampersands and squashed into a single String.
    for parameterKey in oauthParameters.keys.sorted() {
      if !oauthString.isEmpty {
        oauthString.append("&")
      }

      if let value = oauthParameters[parameterKey]?.urlEncodedString() {
        oauthString.append(parameterKey)
        oauthString.append("=")
        oauthString.append("\(value)")
      }
    }

    self.parameterOutput = oauthString.urlEncodedString()
  }

  /// Generates the `oauth_signature` required for the OAuth Header based on the values passed to this objects initializer.
  func signature(key: String, secret: String) -> String {
    let fullString = methodOutput + "&" + urlOutput + "&" + parameterOutput
    let signingKey = key.urlEncodedString() + "&" + secret.urlEncodedString()
    let signature = fullString.hmac(key: signingKey)

    return signature
  }
}

extension String {
  /// Hashes a string based on the provided key.
  /// - Note See https://en.wikipedia.org/wiki/HMAC for more information on this algorithm.
  func hmac(key: String) -> String {
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, self, self.count, &digest)
    let data = Data(bytes: digest, count: Int(CC_SHA1_DIGEST_LENGTH))
    return data.base64EncodedString()
  }

  /// Custom URLEncoding based on the `.urlQueryAllowed` character set.
  func urlEncodedString() -> String {
    var allowedCharacterSet: CharacterSet = .urlQueryAllowed
    allowedCharacterSet.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
    return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? self
  }
}
