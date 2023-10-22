### Training Precautions

- Quality of images
- Quantity of images
- Variety of images
  - mustache
  - long hair
  - short hair

### Why is Face Detection important?

- Face Tracking
  - Where the people are
- Face Analysis
  - Retail Store
  - Medica Store
- Face Recognition
  - Unlock Your Phone

### Face Tracking

- Allows to detect face in a video frame

### Uses of Face Tracking

- Can be used by retailers to count the number of visitors and track their movements. Based on the result, they can adjust their displays.
- Can be used in making sure a user is paying attention. Preventing accidents caused by sleepy drivers.

### Face Analysis

- Allows to detect facial expressions

### Uses of Face Analysis

- Detect the gender of the person
- Detect the emotional state of the person (happy, sand, angry)
- Camera apps can pick the best image out of several images.

### Face Recognition

- A system that identifies or verifies a person from a digital image or video.

### Uses of Face Recognition

- Tagging Photos
- Verification at airports or unlocking devices
- Dorbell cameras
- Social Credit System (China)

### Detect Number Of Faces

```swift
    private func detectFaces(completion: @escaping ([VNFaceObservation]?) -> Void) {
        guard
            let image = UIImage(named: self.photos[self.currentIndex]),
            let cgImage = image.cgImage,
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        else {
            print("Invalid Image")
            completion(nil)
            return
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        DispatchQueue.global().async {
            try? handler.perform([request])
            guard let observations = request.results else {
                print("No Results")
                completion(nil)
                return
            }
            print("Results => \(observations)")
            completion(observations)
        }

    }

```

```swift
// classify the image here
    self.detectFaces { results in
        guard let results else { return }
        // Update The UI
        DispatchQueue.main.async {
            self.label = "Faces: \(results.count)"
        }
    }

```

### Draw Rectangle on detected faces

```swift
extension UIImage {

    func drawOnImage(observations: [VNFaceObservation]) -> UIImage? {
        UIGraphicsBeginImageContext(self.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(5.0)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.size.height)
        for observation in observations {
            let rect = observation.boundingBox
            let normalizedRect = VNImageRectForNormalizedRect(rect, Int(self.size.width), Int(self.size.height)).applying(transform)
            context.stroke(normalizedRect)
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

}
```

```swift
  private func detectFaces(completion: @escaping ([VNFaceObservation]?) -> Void) {
        guard
            let image = UIImage(named: self.photos[self.currentIndex]),
            let cgImage = image.cgImage,
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        else {
            print("Invalid Image")
            completion(nil)
            return
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        DispatchQueue.global().async {
            try? handler.perform([request])
            guard let observations = request.results else {
                print("No Results")
                completion(nil)
                return
            }
            print("Results => \(observations)")
            completion(observations)
        }

    }
```

```swift
     // classify the image here
    self.detectFaces { results in
        guard
            let results,
            let currentImage = self.currentImage
        else { return }

        self.currentImage = currentImage.drawOnImage(observations: results)

        // Update The UI
        DispatchQueue.main.async {
            self.label = "Faces: \(results.count)"
        }
    }
```

### Detect Landmark

```swift

  private func detectFacialLandmarks(completion: @escaping ([VNFaceObservation]?) -> Void) {

        guard let cgImage = currentImage.cgImage,
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(currentImage.imageOrientation.rawValue))
        else {
            return
        }

        let request = VNDetectFaceLandmarksRequest { (request, error) in

            guard let observations = request.results as? [VNFaceObservation] else {
                return completion(nil)
            }

            completion(observations)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }

```

```swift

   // classify the image here
    self.detectFacialLandmarks { observations in
        if let observations = observations {
            // draw facial features
            if let result = self.currentImage.drawLandmarksOnImage(observations: observations) {
                self.currentImage = result
            }
        }
    }

```

```swift

extension UIImage {

    func drawOnImage(observations: [VNFaceObservation]) -> UIImage? {
        UIGraphicsBeginImageContext(self.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(5.0)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.size.height)
        for observation in observations {
            let rect = observation.boundingBox
            let normalizedRect = VNImageRectForNormalizedRect(rect, Int(self.size.width), Int(self.size.height)).applying(transform)
            context.stroke(normalizedRect)
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

}

extension UIImage {

    func drawLandmarksOnImage(observations: [VNFaceObservation]) -> UIImage? {

        UIGraphicsBeginImageContext(self.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError("Unable to initialize context!")
        }

        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))

        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        observations.forEach { face in

            guard let landmark = face.landmarks else {
                return
            }

            let width = face.boundingBox.width * self.size.width
            let height = face.boundingBox.height * self.size.height
            let x = face.boundingBox.origin.x * self.size.width
            let y = face.boundingBox.origin.y * self.size.height

            let faceRect = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))

            context.setStrokeColor(UIColor.red.cgColor)
            context.stroke(faceRect, width: 4.0)

            if let leftEye = landmark.leftEye {
                self.drawLines(context: context, points: leftEye.normalizedPoints, boundingBox: face.boundingBox)
            }

            if let rightEye = landmark.rightEye {
                self.drawLines(context: context, points: rightEye.normalizedPoints, boundingBox: face.boundingBox)
            }
            if let innerLips = landmark.innerLips {
                self.drawLines(context: context, points: innerLips.normalizedPoints, boundingBox: face.boundingBox)
            }

            if let outerLips = landmark.outerLips {
                self.drawLines(context: context, points: outerLips.normalizedPoints, boundingBox: face.boundingBox)
            }

            if let leftPupil = landmark.leftPupil {
                self.drawLines(context: context, points: leftPupil.normalizedPoints, boundingBox: face.boundingBox)
            }

            if let rightPupil = landmark.rightPupil {
                self.drawLines(context: context, points: rightPupil.normalizedPoints, boundingBox: face.boundingBox)
            }

        }

        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()


        return result
    }



    private func drawLines(context: CGContext, points: [CGPoint], boundingBox: CGRect) {

        let width = boundingBox.width * self.size.width
        let height = boundingBox.height * self.size.height
        let x = boundingBox.origin.x * self.size.width
        let y = boundingBox.origin.y * self.size.height

        context.setStrokeColor(UIColor.yellow.cgColor)

        var lastPoint = CGPoint.zero

        points.forEach { currentPoint in

            if lastPoint == CGPoint.zero {
                context.move(to: CGPoint(x: currentPoint.x * width + x, y: currentPoint.y * height + y))
                lastPoint = currentPoint
            } else {
                context.addLine(to: CGPoint(x: currentPoint.x * width + x, y: currentPoint.y * height + y))
            }

        }

        context.closePath()
        context.setLineWidth(8.0)
        context.drawPath(using: .stroke)

    }


}


```
