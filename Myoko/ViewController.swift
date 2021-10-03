//
//  ViewController.swift
//  Myoko
//
//  Created by Subomi Popoola on 10/2/21.
//

import UIKit
import ARKit
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    private var node: SCNNode!
//    private var lastRotation: Float = 0
    private let configuration = ARWorldTrackingConfiguration()
    
//    var PCoordx: Float = 0.0
//    var PCoordy: Float = 0.0
//    var PCoordz: Float = 0.0
    
    var fileName: String = "car.scn"
    
    let buttonView = UIView()
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        addTapGesture()
        self.createScene(x: -2.0, y: -2.0, z: -1.2)
//        self.addPinchGesture()
//        self.addRotationGesture()
//        self.addDragRecognizer()
        attachMiniView()
        requestSpeechAuthorization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func attachMiniView() {
        buttonView.frame.origin.x = 0.0
        buttonView.frame.size.width = sceneView.frame.size.width
        buttonView.frame.origin.y = (sceneView.frame.size.height - 30.0)
        buttonView.frame.size.height = 30.0
        buttonView.backgroundColor = .clear
        buttonView.isUserInteractionEnabled = true
        sceneView.addSubview(buttonView)
    }
    
    func makeAction(action: [String]) {
        switch action {
        case "right":
            translocateEnitreNode(ix: 2.0, iy: 0.0, iz: 0.0)
        case "left":
            translocateEnitreNode(ix: -2.0, iy: 0.0, iz: 0.0)
        default:
            print("No action found...")
        }
    }
    
    func createScene(x: Float = -2.0, y: Float = -2.0, z: Float = -1.2) {
        guard let scene =  SCNScene(named: fileName) else {
            fatalError("Unable to load scene file.")
        }
        node = SCNNode()
        for nod in scene.rootNode.childNodes {
            node.addChildNode(nod)
        }
        node.position = SCNVector3(x, y, z)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func translocateSpecificNode(ix: Float, iy: Float, iz: Float, name: String) {
        for each_node in node.childNodes {
            if each_node.name == name {
                let x = each_node.position.x
                let y = each_node.position.y
                let z = each_node.position.z
                each_node.position = SCNVector3(x + ix, y + iy, z + iz)
            }
        }
    }
    
    func translocateEnitreNode(ix: Float, iy: Float, iz: Float) {
        let x = node.position.x
        let y = node.position.y
        let z = node.position.z
        node.position = SCNVector3(x + ix, y + iy, z + iz)
    }
    
    func decreaseEntireScale(by: Float) {
        let x = node.scale.x
        let y = node.scale.y
        let z = node.scale.z
        node.scale = SCNVector3(x / by, y / by, z / by)
    }
    
    func decreaseSpecificScale(by: Float, name: String) {
        for each_node in node.childNodes {
            if each_node.name == name {
                let x = each_node.scale.x
                let y = each_node.scale.y
                let z = each_node.scale.z
                each_node.scale = SCNVector3(x / by, y / by, z / by)
            }
        }
    }
    
    func increaseEntireScale(by: Float) {
        let x = node.scale.x
        let y = node.scale.y
        let z = node.scale.z
        node.scale = SCNVector3(x * by, y * by, z * by)
    }
    
    func increaseSpecificScale(by: Float, name: String) {
        for each_node in node.childNodes {
            if each_node.name == name {
                let x = each_node.scale.x
                let y = each_node.scale.y
                let z = each_node.scale.z
                each_node.scale = SCNVector3(x * by, y * by, z * by)
            }
        }
    }
    
    func rotateVehicle(by: Float) {
        node.eulerAngles.y += by
    }
    
    func cancelRecording() {
            recognitionTask?.finish()
            recognitionTask = nil
            
            // stop audio
            request.endAudio()
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    //MARK: - Check Authorization Status
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Enabled..")
                case .denied:
                    print("User denied access to speech recognition")
                case .restricted:
                    print("Speech recognition restricted on this device")
                case .notDetermined:
                    print("Speech recognition not yet authorized")
                @unknown default:
                    return
                }
            }
        }
    }
    
    //MARK: - Recognize Speech
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            return
        }
        if !myRecognizer.isAvailable {
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = String(bestString[indexTo...])
                }
                let commands = lastString.components(separatedBy: ", ")
                makeAction(action: commands)
            } else if let error = error {
                print(error)
            }
        })
      }
    
    
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        buttonView.addGestureRecognizer(tapGesture)
    }
    
//    @objc func didTap(_ gesture: UITapGestureRecognizer) {
//        let tapLocation = gesture.location(in: sceneView)
//        let results = sceneView.hitTest(tapLocation, types: .featurePoint)
//        guard let result = results.first else {
//            return
//        }
//        let translation = result.worldTransform.translation
//        guard let node = self.node else {
//            self.addBox(x: translation.x, y: translation.y, z: translation.z)
//            return
//        }
//        node.position = SCNVector3Make(translation.x, translation.y, translation.z)
//        self.sceneView.scene.rootNode.addChildNode(self.node)
//    }
    
    @objc func didTap(_ gesture: UITapGestureRecognizer) {
        if isRecording == true {
            cancelRecording()
            isRecording = false
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
        }
    }
    
//    private func addPinchGesture() {
//           let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
//           self.sceneView.addGestureRecognizer(pinchGesture)
//       }
//
//       @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
//           let originalScale = node.scale
//
//           switch gesture.state {
//           case .began:
//               gesture.scale = CGFloat(originalScale.x)
//           case .changed:
//               var newScale: SCNVector3
//               if gesture.scale < 0.5 {
//                   newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
//               } else if gesture.scale > 3 {
//                   newScale = SCNVector3(3, 3, 3)
//               } else {
//                   newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
//               }
//               node.scale = newScale
//           default:
//               break
//           }
//       }
//
//       private func addRotationGesture() {
//           let panGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
//           self.sceneView.addGestureRecognizer(panGesture)
//       }
//
//       @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
//           switch gesture.state {
//           case .changed:
//               // change node y angel
//               node.eulerAngles.y = self.lastRotation + Float(gesture.rotation)
//           case .ended:
//               // save last rotation
//               self.lastRotation += Float(gesture.rotation)
//           default:
//               break
//           }
//       }
    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//
//        //1. Get The Current Touch Point
//        guard let currentTouchPoint = touches.first?.location(in: self.sceneView),
//            //2. Get The Next Feature Point Etc
//            let hitTest = sceneView.hitTest(currentTouchPoint, types: .existingPlane).first else { return }
//
//        //3. Convert To World Coordinates
//        let worldTransform = hitTest.worldTransform
//
//        //4. Set The New Position
//        let newPosition = SCNVector3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
//
//        //5. Apply To The Node
//        node.simdPosition = float3(newPosition.x, newPosition.y, newPosition.z)
//
//    }
//
    
//    func addDragRecognizer() {
//        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
//        sceneView.addGestureRecognizer(panRecognizer)
//    }
//
//    @objc func handlePan(sender: UIPanGestureRecognizer) {
//        switch sender.state {
//            case .began:
//                let location = sender.location(in: self.sceneView)
//                guard let hitNodeResult = self.sceneView.hitTest(location,
//                                                                 options: nil).first else { return }
//                self.PCoordx = hitNodeResult.worldCoordinates.x
//                self.PCoordy = hitNodeResult.worldCoordinates.y
//                self.PCoordz = hitNodeResult.worldCoordinates.z
//            case .changed:
//                // when you start to pan in screen with your finger
//                // hittest gives new coordinates of touched location in sceneView
//                // coord-pcoord gives distance to move or distance paned in sceneview
//                let hitNode = sceneView.hitTest(sender.location(in: sceneView), options: nil)
//                if let coordx = hitNode.first?.worldCoordinates.x,
//                    let coordy = hitNode.first?.worldCoordinates.y,
//                    let coordz = hitNode.first?.worldCoordinates.z {
//                    let action = SCNAction.moveBy(x: CGFloat(coordx - self.PCoordx),
//                                                  y: CGFloat(coordy - self.PCoordy),
//                                                  z: CGFloat(coordz - self.PCoordz),
//                                                  duration: 0.0)
//                    self.node.runAction(action)
//
//                    self.PCoordx = coordx
//                    self.PCoordy = coordy
//                    self.PCoordz = coordz
//                }
//
//                sender.setTranslation(CGPoint.zero, in: self.sceneView)
//            case .ended:
//                self.PCoordx = 0.0
//                self.PCoordy = 0.0
//                self.PCoordz = 0.0
//            default:
//                break
//            }
//
//    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

