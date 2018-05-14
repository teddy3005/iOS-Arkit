//
//  ViewController.swift
//  LocateIt
//
//  Created by Alan Chen on 5/10/18.
//  Copyright © 2018 Alphie. All rights reserved.
//

import UIKit
import CoreLocation
import ARKit
import MapKit

let kStartingPosition = SCNVector3(0, 0, -0.6)
let kAnimationDurationMoving: TimeInterval = 0.2
let kMovingLengthPerLoop: CGFloat = 0.05
let kRotationRadianPerLoop: CGFloat = 0.2

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var arKitView: ARSCNView!
    
    var drone = Drone()
    let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsPointsOfInterest = true
      
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let sourcecoordinate = locationManager.location?.coordinate
        let destCoordinates = CLLocationCoordinate2DMake(37.3793877, -121.9100495)
        
        let sourcePlacemark = MKPlacemark(coordinate: sourcecoordinate!)
        let destPlacemark = MKPlacemark(coordinate: destCoordinates)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destItem = MKMapItem(placemark: destPlacemark)
        
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = sourceItem
        directionRequest.destination = destItem
        directionRequest.transportType = .walking
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate(completionHandler:{
            response, error in
            
//            gaurd let response = response else{
//                if let error = error{
//                    print("something went wrong")
//                }
//                return
//            }
            let route = response?.routes[0]
            self.mapView.add((route?.polyline)!, level: .aboveRoads)
            
            let rekt = route?.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegionForMapRect(rekt!), animated: true)
        })
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    
    
    func locationManager(_ _manage: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location = locations[0]

        let center = location.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)

        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
    }
    
    
    
//----
//    func enableBasicLocationServices() {
//
//
//        switch CLLocationManager.authorizationStatus() {
//        case .notDetermined:
//            // Request when-in-use authorization initially
//            locationManager.requestWhenInUseAuthorization()
//            break
//
//        case .restricted, .denied:
//            // Disable location features
//            print("Disable Location Based Features")
//            break
//
//        case .authorizedWhenInUse, .authorizedAlways:
//            // Enable location features
//            print("Enable When In Use Features")
//            startMonitoringLocation()
//            break
//        }
//    }
    
//    func locationManager(_ manager: CLLocationManager,
//                         didChangeAuthorization status: CLAuthorizationStatus) {
//        switch status {
//        case .restricted, .denied:
//            // Disable location features
//            print("Disable Location Based Features")
//            break
//
//        case .authorizedWhenInUse:
//            // Enable location features
//            print("Enable When In Use Features")
//            startMonitoringLocation()
//            break
//
//        case .notDetermined, .authorizedAlways:
//            break
//        }
//    }
//
//    func startMonitoringLocation(){
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = 1.0  // In meters.
//        locationManager.startUpdatingLocation()
//    }
    
//    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
//        let lastLocation = locations.last!
//        print(lastLocation.coordinate)
//        // Do something with the location.
//    }
    
//-----
    
//    let regionRadius: CLLocationDistance = 1000
//    func centerMapOnLocation(location: CLLocation) {
//        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
//                                                                  regionRadius, regionRadius)
//        mapView.setRegion(coordinateRegion, animated: true)
//    }
    
    func setupScene() {
        let scene = SCNScene()
        arKitView.scene = scene
    }
    
    func setupConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        arKitView.session.run(configuration)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupConfiguration()
        addDrone()
    }
    
    class Drone: SCNNode {
        func load() {
            guard let virtualObjectScene = SCNScene(named: "Drone.scn") else { return }
            let wrapperNode = SCNNode()
            for child in virtualObjectScene.rootNode.childNodes {
                wrapperNode.addChildNode(child)
            }
            addChildNode(wrapperNode)
        }
    }
    
    func addDrone() {
        drone.load()
        arKitView.scene.rootNode.addChildNode(drone)
    }
    
    @IBAction func upPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: 0, y: kMovingLengthPerLoop, z: 0, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }
    
    
    @IBAction func downPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: 0, y: -kMovingLengthPerLoop, z: 0, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }
    @IBAction func leftPressed(_ sender: UILongPressGestureRecognizer) {
        let x = -deltas().cos
        let z = deltas().sin
        moveDrone(x: x, z: z, sender: sender)
    }
    @IBAction func rightPressed(_ sender: UILongPressGestureRecognizer) {
        let x = deltas().cos
        let z = -deltas().sin
        moveDrone(x: x, z: z, sender: sender)
    }
    @IBAction func forwardPressed(_ sender: UILongPressGestureRecognizer) {
        let x = -deltas().sin
        let z = -deltas().cos
        moveDrone(x: x, z: z, sender: sender)
    }
    @IBAction func backPressed(_ sender: UILongPressGestureRecognizer) {
        let x = deltas().sin
        let z = deltas().cos
        moveDrone(x: x, z: z, sender: sender)
    }
    @IBAction func RotateLeftPressed(_ sender: UILongPressGestureRecognizer) {
        rotateDrone(yRadian: kRotationRadianPerLoop, sender: sender)
    }
    @IBAction func RotateRightPressed(_ sender: UILongPressGestureRecognizer) {
        rotateDrone(yRadian: -kRotationRadianPerLoop, sender: sender)
    }
    
    private func rotateDrone(yRadian: CGFloat, sender: UILongPressGestureRecognizer) {
        let action = SCNAction.rotateBy(x: 0, y: yRadian, z: 0, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }
    
    private func moveDrone(x: CGFloat, z: CGFloat, sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: x, y: 0, z: z, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }
    
    private func execute(action: SCNAction, sender: UILongPressGestureRecognizer) {
        let loopAction = SCNAction.repeatForever(action)
        if sender.state == .began {
            drone.runAction(loopAction)
        } else if sender.state == .ended {
            drone.removeAllActions()
        }
    }
    
    private func deltas() -> (sin: CGFloat, cos: CGFloat) {
        return (sin: kMovingLengthPerLoop * CGFloat(sin(drone.eulerAngles.y)), cos: kMovingLengthPerLoop * CGFloat(cos(drone.eulerAngles.y)))
    }
    
    
    
    
    
    
}

