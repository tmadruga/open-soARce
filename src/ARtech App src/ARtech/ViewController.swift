//
//  ViewController.swift
//  ARtech
//
//  Modifications by Tiffany Madruga 10/25/2019.
//  Original material created by Prayash Thapa on 11/12/18.
//  Use under MIT License.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    /// Primary SceneKit view that renders the AR session
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var instructions: UILabel!
    @IBOutlet var tap: UITapGestureRecognizer!
    
    /// A serial queue for thread safety when modifying SceneKit's scene graph.
    let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
    
    //store variables here
    var trackingImages = [String: TrackingImage]()
    // MARK: - Lifecycle
    
    // Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        loadData()
        // Show statistics such as FPS and timing information (useful during development)
        sceneView.showsStatistics = true
        
        // Enable environment-based lighting
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
    }
 
    
    // Notifies the view controller that its view is about to be added to a view hierarchy.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // edit this line
        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
                fatalError("Missing expected asset catalog resources.")
        }
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = refImages
        
        // Run the view's session
        // not sure if the run options are necessary as of rn ... we will investigate and see
        sceneView.session.run(configuration, options: ARSession.RunOptions(arrayLiteral: [.resetTracking, .removeExistingAnchors]))
    }
    
    // Notifies the view controller that its view is about to be removed from a view hierarchy.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

}
