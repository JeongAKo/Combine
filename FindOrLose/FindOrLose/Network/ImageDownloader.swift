/// Copyright (c) 2020 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import UIKit
import Combine



enum ImageDownloader {
//  static func download(url: String, completion: @escaping (UIImage?) -> Void) {
//    let url = URL(string: url)!
//
//    URLSession.shared.dataTask(with: url) { data, response, error in
//      guard
//        let httpURLResponse = response as? HTTPURLResponse,
//        httpURLResponse.statusCode == 200,
//        let data = data, error == nil,
//        let image = UIImage(data: data)
//        else {
//          completion(nil)
//          return
//      }
//      completion(image)
//    }.resume()
//  }
  
  
  
  // 1
  static func download(url: String) -> AnyPublisher<UIImage, GameError> {
    guard let url = URL(string: url) else {
      return Fail(error: GameError.invalidURL)
        .eraseToAnyPublisher()
    }

    //2
    return URLSession.shared.dataTaskPublisher(for: url)
      //3
      .tryMap { response -> Data in
        guard
          let httpURLResponse = response.response as? HTTPURLResponse,
          httpURLResponse.statusCode == 200
          else {
            throw GameError.statusCode
        }
        
        return response.data
      }
      //4
      .tryMap { data in
        guard let image = UIImage(data: data) else {
          throw GameError.invalidImage
        }
        return image
      }
      //5
      .mapError { GameError.map($0) }
      //6
      .eraseToAnyPublisher()
  }

}
