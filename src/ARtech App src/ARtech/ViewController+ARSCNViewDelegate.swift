//
//  ViewController+ARSCNViewDelegate.swift
//  ARtech
//
//  Modifications by Tiffany Madruga 10/25/2019.
//  Original material created by Prayash Thapa on 11/12/18.
//  Use under MIT License.
//
//

import UIKit
import SceneKit
import ARKit
import Firebase

extension ViewController: ARSCNViewDelegate {
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        guard let name = imageAnchor.referenceImage.name else { return }
        guard let tracking = trackingImages[name] else {return }

        
        // Delegate rendering tasks to our `updateQueue` thread to keep things thread-safe!
        updateQueue.async {
            let physicalWidth = imageAnchor.referenceImage.physicalSize.width
            let physicalHeight = imageAnchor.referenceImage.physicalSize.height
            
            let testWidth = physicalWidth * 2
            
            // Create a plane geometry to visualize the initial position of the detected image
            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
            
            // This bit is important. It helps us create occlusion so virtual things stay hidden behind the detected image
            mainPlane.firstMaterial?.colorBufferWriteMask = .alpha
            
            // Create a SceneKit root node with the plane geometry to attach to the scene graph
            // This node will hold the virtual UI in place
            let mainNode = SCNNode(geometry: mainPlane)
            mainNode.eulerAngles.x = -.pi / 2
            mainNode.renderingOrder = -1
            mainNode.opacity = 1
            
            // Add the plane visualization to the scene
            node.addChildNode(mainNode)
            
            // Perform a quick animation to visualize the plane on which the image was detected.
            // We want to let our users know that the app is responding to the tracked image.
            self.highlightDetection(on: mainNode, width: physicalWidth, height: physicalHeight, completionHandler: {
                
                // Decide which nodes to display
                if tracking.webNode{
                    self.displayWebView(on: mainNode, xOffset: testWidth, tracking: tracking)
                }
                if tracking.textNode{
                    self.displayTextView(on: mainNode, xOffset: testWidth, tracking: tracking)
                }
                if tracking.imageNode{
                    self.displayDetailView(on: mainNode, xOffset: testWidth, tracking: tracking, imageAnchor: imageAnchor)
                }
                
            })
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - SceneKit Helpers
    
    // function to display images after being recognized
    func displayDetailView(on rootNode: SCNNode, xOffset: CGFloat, tracking: TrackingImage, imageAnchor: ARImageAnchor) {

        let detailPlane = SCNPlane(width: 0.25, height: 0.5)
        let detailNode = SCNNode(geometry: detailPlane)

        detailPlane.cornerRadius = 0.0
        detailNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: tracking.image)
        detailNode.position.z -= 0.5
        detailNode.opacity = 0
        
        
        rootNode.addChildNode(detailNode)

        detailNode.runAction(.sequence([
            .wait(duration: 1.0),
            .fadeOpacity(to: 1.0, duration: 1.5),
            .moveBy(x: xOffset * -1.5, y: -0.13, z: -0.05, duration: 1.5),
            .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
        ])
        )
    }
    
    // function to display text after image is recognized
    func displayTextView(on rootNode: SCNNode, xOffset: CGFloat, tracking: TrackingImage) {
        let spacing: Float = 0.005
        var titleNodeHeight: Float = 0.0
        let detailPlane = SCNPlane(width: xOffset, height: xOffset * 1.4)
        detailPlane.cornerRadius = 0.0

        if tracking.name != "" {
            let titleNode = textNode(tracking.name, tracking: tracking, font: UIFont.systemFont(ofSize: 25, weight: UIFont.Weight.heavy), maxWidth: 200)
            titleNode.pivotOnTopLeft()

            titleNode.position.x -= (Float(detailPlane.width / 4) + spacing)
            titleNode.position.y += (Float(detailPlane.height / 4) + spacing)
            titleNodeHeight = titleNode.position.y
            rootNode.addChildNode(titleNode)
            titleNode.runAction(.sequence([
                .wait(duration: 1.0),
                .moveBy(x: xOffset * -0.73, y: 0, z: -0.05, duration: 1.5),
                .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
            ])
            )
        }
        
        if tracking.bio != "" {
            let bioNode = textNode(tracking.bio, tracking: tracking, font: UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium), maxWidth: 200)
            bioNode.pivotOnTopLeft()
            bioNode.position.x = (Float(detailPlane.width / 4) + spacing)
            if tracking.name != "" {
               bioNode.position.y = titleNodeHeight
            }
            else{
                bioNode.position.y += spacing
                
            }
            bioNode.opacity = 0
            rootNode.addChildNode(bioNode)
            
            bioNode.runAction(.sequence([
                .wait(duration: 3.0),
                .fadeOpacity(to: 1.0, duration: 1.5),
                .moveBy(x: xOffset * 0.017, y: 0, z: -0.05, duration: 1.5),
                .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
            ])
            )
            
        }
    }
    
    // If we want to include a website, we call this
    func displayWebView(on rootNode: SCNNode, xOffset: CGFloat, tracking:TrackingImage) {
        // Xcode yells at us about the deprecation of UIWebView in iOS 12.0, but there is currently
        // a bug that does now allow us to use a WKWebView as a texture for our webViewNode
        // Note that UIWebViews should only be instantiated on the main thread!
        DispatchQueue.main.async {
            let request = URLRequest(url: URL(string: tracking.source )!)
            let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 1008))
            webView.loadRequest(request)
            
            let webViewPlane = SCNPlane(width: xOffset * 2, height: xOffset * 1.4 * 2)
            webViewPlane.cornerRadius = 0.0
            
            let webViewNode = SCNNode(geometry: webViewPlane)
            
            // Set the web view as webViewPlane's primary texture
            webViewNode.geometry?.firstMaterial?.diffuse.contents = webView
            webViewNode.position.z -= 0.5
            webViewNode.opacity = 0
            
            rootNode.addChildNode(webViewNode)
            webViewNode.runAction(.sequence([
                .wait(duration: 3.0),
                .fadeOpacity(to: 1.0, duration: 1.5),
                .moveBy(x: xOffset * 2.3, y: 0, z: -0.05, duration: 1.5),
                .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
            ])
            )
        }
        
    }
    
    //Highlight photo for user
    func highlightDetection(on rootNode: SCNNode, width: CGFloat, height: CGFloat, completionHandler block: @escaping (() -> Void)) {
        let planeNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        planeNode.position.z += 0.1
        planeNode.opacity = 0
        
        rootNode.addChildNode(planeNode)
        planeNode.runAction(self.imageHighlightAction) {
            block()
        }
    }
    
    //This loads our JSON data
    func loadData() {
        let jsonUrl = "https://ms-thesis-17de9.firebaseio.com/data.json"
        
        guard let url = URL(string: jsonUrl) else{
            print("Error: cannot create URL")
            return
        }

         guard let data = try? Data(contentsOf: url) else {
             fatalError("Unable to load JSON")
         }

        
         let decoder = JSONDecoder()

         guard let loadedTrackingImages = try? decoder.decode([String: TrackingImage].self, from: data) else {
             fatalError("Unable to parse JSON.")
         }

         trackingImages = loadedTrackingImages
     }

    // This is how we generate text from our JSON file.
    func textNode(_ str: String, tracking: TrackingImage, font: UIFont, maxWidth: Int? = nil) -> SCNNode {
         let text = SCNText(string: str, extrusionDepth: 0)
         let trackingScale = 0.0005

         text.flatness = 0.1
         text.font = font

         if let maxWidth = maxWidth {
             text.containerFrame = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: 500))
             text.isWrapped = true
         }

         let textNode = SCNNode(geometry: text)
         textNode.scale = SCNVector3(trackingScale, trackingScale, trackingScale)
         
         //adding grey background
         
         let minVec = textNode.boundingBox.min
         let maxVec = textNode.boundingBox.max
         let bound = SCNVector3Make(maxVec.x - minVec.x,
                                    maxVec.y - minVec.y,
                                    maxVec.z - minVec.z);
         
         let plane = SCNPlane(width: CGFloat(bound.x + 50),
                             height: CGFloat(bound.y + 50))
         plane.cornerRadius = 0.5
        plane.firstMaterial?.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.9)
         
         let planeNode = SCNNode(geometry: plane)
         planeNode.position = SCNVector3(CGFloat( minVec.x) + CGFloat(bound.x) / 2 ,
                                         CGFloat( minVec.y) + CGFloat(bound.y) / 2,CGFloat(minVec.z - 0.01))

         textNode.addChildNode(planeNode)


         return textNode
     }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
    
}

//from spot the scientist
extension SCNNode {
    var height: Float {
        return (boundingBox.max.y - boundingBox.min.y) * scale.y
    }

    func pivotOnTopLeft() {
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation(min.x, max.y, 0)
    }

    func pivotOnTopCenter() {
        let (_, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation(0, max.y, 0)
    }
}
