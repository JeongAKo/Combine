/// Copyright (c) 2019 Razeware LLC
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

import UIKit
import Combine


class GameViewController: UIViewController {
  // MARK: - Variables
  var subscriptions: Set<AnyCancellable> = []
  var gameTimer: AnyCancellable?

  
  var gameState: GameState = .stop {
    didSet {
      switch gameState {
        case .play:
          playGame()
        case .stop:
          stopGame()
      }
    }
  }

  var gameImages: [UIImage] = []
  var gameLevel = 0
  var gameScore = 0

  // MARK: - Outlets

  @IBOutlet weak var gameStateButton: UIButton!

  @IBOutlet weak var gameScoreLabel: UILabel!

  @IBOutlet var gameImageView: [UIImageView]!

  @IBOutlet var gameImageButton: [UIButton]!

  @IBOutlet var gameImageLoader: [UIActivityIndicatorView]!

  // MARK: - View Controller Life Cycle

  override func viewDidLoad() {
    precondition(!Bundle.main.accessToken.isEmpty, "Please provide a valid Unsplash access token!")

    title = "Find or Lose"
    gameScoreLabel.text = "Score: \(gameScore)"
  }

  // MARK: - Game Actions

  @IBAction func playOrStopAction(sender: UIButton) {
    gameState = gameState == .play ? .stop : .play
  }

  @IBAction func imageButtonAction(sender: UIButton) {
    let selectedImages = gameImages.filter { $0 == gameImages[sender.tag] }
    
    if selectedImages.count == 1 {
      playGame()
    } else {
      gameState = .stop
    }
  }

  // MARK: - Game Functions

  func playGame() {
    gameTimer?.cancel()


    gameStateButton.setTitle("Stop", for: .normal)

    gameLevel += 1
    title = "Level: \(gameLevel)"

    gameScoreLabel.text = "Score: \(gameScore)"
    gameScore += 200

    resetImages()
    startLoaders()

//    UnsplashAPI.randomImage { [unowned self] randomImageResponse in
//      guard let randomImageResponse = randomImageResponse else {
//        DispatchQueue.main.async {
//          self.gameState = .stop
//        }
//
//        return
//      }

    
    // 1
    let firstImage = UnsplashAPI.randomImage()
      // 2
      .flatMap { randomImageResponse in
        ImageDownloader.download(url: randomImageResponse.urls.regular)
      }

    
    let secondImage = UnsplashAPI.randomImage()
      .flatMap { randomImageResponse in
        ImageDownloader.download(url: randomImageResponse.urls.regular)
      }

    
    // 1
    firstImage.zip(secondImage)
      // 2
      .receive(on: DispatchQueue.main)
      // 3
      .sink(receiveCompletion: { [unowned self] completion in
        // 4
        switch completion {
        case .finished: break
        case .failure(let error):
          print("Error: \(error)")
          self.gameState = .stop
        }
      }, receiveValue: { [unowned self] first, second in
        // 5
        self.gameImages = [first, second, second, second].shuffled()

        self.gameScoreLabel.text = "Score: \(self.gameScore)"

        // 1
        self.gameTimer = Timer.publish(every: 0.1, on: RunLoop.main, in: .common)
          // 2
          .autoconnect()
          // 3
          .sink { [unowned self] _ in
            self.gameScoreLabel.text = "Score: \(self.gameScore)"
            self.gameScore -= 10

            if self.gameScore < 0 {
              self.gameScore = 0

              self.gameTimer?.cancel()
            }
          }



        self.stopLoaders()
        self.setImages()
      })
      // 6
      .store(in: &subscriptions)


    
    
  }

  func stopGame() {
    subscriptions.forEach { $0.cancel() }

    gameTimer?.cancel()


    gameStateButton.setTitle("Play", for: .normal)

    title = "Find or Lose"

    gameLevel = 0

    gameScore = 0
    gameScoreLabel.text = "Score: \(gameScore)"

    stopLoaders()
    resetImages()
  }

  // MARK: - UI Functions

  func setImages() {
    if gameImages.count == 4 {
      for (index, gameImage) in gameImages.enumerated() {
        gameImageView[index].image = gameImage
      }
    }
  }

  func resetImages() {
    subscriptions = []

    gameImages = []

    gameImageView.forEach { $0.image = nil }
  }

  func startLoaders() {
    gameImageLoader.forEach { $0.startAnimating() }
  }

  func stopLoaders() {
    gameImageLoader.forEach { $0.stopAnimating() }
  }
}
