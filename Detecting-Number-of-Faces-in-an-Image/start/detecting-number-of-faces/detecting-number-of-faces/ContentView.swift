//
//  ContentView.swift
//  ImageClassificationSwiftUI
//
//  Created by Mohammad Azam on 2/3/20.
//  Copyright © 2020 Mohammad Azam. All rights reserved.
//

import SwiftUI
import Vision

struct ContentView: View {
    
    let photos = ["face","friends-sitting","people-sitting","ball","bird"]
    @State private var currentIndex: Int = 0
    
    @State private var currentImage: UIImage = UIImage(named: "face")!
    
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
    
    var body: some View {
        VStack {
            Image(uiImage: currentImage)
            .resizable()
                .aspectRatio(contentMode: .fit)
            
            HStack {
                Button("Previous") {
                    
                    if self.currentIndex >= self.photos.count {
                        self.currentIndex = self.currentIndex - 1
                    } else {
                        self.currentIndex = 0
                    }
                    
                    self.currentImage = UIImage(named: self.photos[self.currentIndex])!
                    
                    }.padding()
                    .foregroundColor(Color.white)
                    .background(Color.gray)
                    .cornerRadius(10)
                    .frame(width: 100)
                
                Button("Next") {
                    if self.currentIndex < self.photos.count - 1 {
                        self.currentIndex = self.currentIndex + 1
                    } else {
                        self.currentIndex = 0
                    }
                    
                    self.currentImage = UIImage(named: self.photos[self.currentIndex])!
                }
                .padding()
                .foregroundColor(Color.white)
                .frame(width: 100)
                .background(Color.gray)
                .cornerRadius(10)
            
                
                
            }.padding()
            
            Button("Classify") {
                
                // classify the image here
                self.detectFacialLandmarks { observations in
                    if let observations = observations {
                        // draw facial features
                        if let result = self.currentImage.drawLandmarksOnImage(observations: observations) {
                            self.currentImage = result
                        }
                    }
                }
                
            }.padding()
            .foregroundColor(Color.white)
            .background(Color.green)
            .cornerRadius(8)
            
            Text("")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



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
