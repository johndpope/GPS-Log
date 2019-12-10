//
//  MapView.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import SQLite3
import SceneKit
import MapKit

/// 3D scene that draws a map from a session.
class MapView: SCNView
{
    /// Initializer.
    /// - Parameter frame: Source frame.
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        Initialize()
    }
    
    /// Initializer.
    /// - Parameter frame: Source frame.
    /// - Parameter options: Options for the view.
    override init(frame: CGRect, options: [String: Any]? = nil)
    {
        super.init(frame: frame, options: options)
        Initialize()
    }
    
    /// Initializer.
    /// - Parameter coder: See Apple documentation.
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        Initialize()
    }
    
    /// Initializes the scene. Adds light and camera.
    private func Initialize()
    {
        let Scene = SCNScene()
        self.scene = Scene
        self.scene?.rootNode.addChildNode(MakeCamera())
        self.scene?.rootNode.addChildNode(MakeLight())
        self.scene?.background.contents = UIColor(red: 219.0 / 255.0, green: 215.0 / 255.0, blue: 210.0 / 255.0, alpha: 1.0)
        self.allowsCameraControl = true
        #if DEBUG
        self.showsStatistics = true
        #endif
    }
    
    /// Creates and returns a node with a camera.
    /// - Returns: Scene node with a camera.
    private func MakeCamera() -> SCNNode
    {
        let Camera = SCNCamera()
        Camera.fieldOfView = 90.0
        Camera.orthographicScale = 20.0
        Camera.usesOrthographicProjection = false
        CameraNode = SCNNode()
        CameraNode.camera = Camera
        CameraNode.position = SCNVector3(0.0, 0.0, 10.0)
        CameraNode.name = "Camera"
        return CameraNode
    }
    
    /// Creates and returns a node with a light.
    /// - Returns: Scene node with a light.
    private func MakeLight() -> SCNNode
    {
        let Light = SCNLight()
        Light.type = .omni
        Light.color = UIColor.white
        LightNode = SCNNode()
        LightNode.light = Light
        LightNode.position = SCNVector3(0.0, 0.0, 10.0)
        LightNode.name = "Light"
        return LightNode
    }
    
    var CameraNode: SCNNode!
    var LightNode: SCNNode!
    
    /// Create a "line" and return it in a scene node.
    /// - Note: The line is really a very thin box. This makes lines a rather heavy operation.
    /// - Parameter From: Starting point of the line.
    /// - Parameter To: Ending point of the line.
    /// - Parameter Color: The color of the line.
    /// - Parameter LineWidth: Width of the line - defaults to 0.01.
    /// - Returns: Node with the specified line. The node has the name "GridNodes".
    public func MakeLine(From: SCNVector3, To: SCNVector3, Color: UIColor, LineWidth: CGFloat = 0.01) -> SCNNode
    {
        var Width: Float = 0.01
        var Height: Float = 0.01
        let FinalLineWidth = Float(LineWidth)
        if From.y == To.y
        {
            Width = abs(From.x - To.x)
            Height = FinalLineWidth
        }
        else
        {
            Height = abs(From.y - To.y)
            Width = FinalLineWidth
        }
        let Line = SCNBox(width: CGFloat(Width), height: CGFloat(Height), length: 0.01,
                          chamferRadius: 0.0)
        Line.materials.first?.diffuse.contents = Color
        let Node = SCNNode(geometry: Line)
        Node.position = From
        Node.name = "SegmentLine"
        return Node
    }
    
    /// Create a map from the session data.
    /// - Parameter TheSession: Session data used to create a map.
    func DisplaySession(_ TheSession: SessionData)
    {
        var MinX = 1000000000.0
        var MinY = 1000000000.0
        for SomeLocation in TheSession.Locations
        {
            let MKPoint = MKMapPoint(SomeLocation.Location!.coordinate)
            if MinX > MKPoint.x
            {
                MinX = MKPoint.x
            }
            if MinY > MKPoint.y
            {
                MinY = MKPoint.y
            }
        }
        print("MinXY=\(MinX),\(MinY)")
        for SomeLocation in TheSession.Locations
        {
            let MKPoint = MKMapPoint(SomeLocation.Location!.coordinate)
            let AdjustedX = MKPoint.x - MinX
            let AdjustedY = MKPoint.y - MinY
            print("\(SomeLocation.Location!.coordinate) = (\(AdjustedX),\(AdjustedY))")
        }
    }
}

