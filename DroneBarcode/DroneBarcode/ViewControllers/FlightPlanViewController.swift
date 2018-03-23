//
//  FlightPlanViewController.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import CoreLocation
import UIKit

class FlightPlanViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var flightMapView: MKMapView!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var flightPathCoordinateList: [CLLocationCoordinate2D] = []
    private var isRecording = false
    private var locationManager: CLLocationManager!
    private var flightPathLine: MKPolyline?
    private var loadingAlert: UIAlertController!
    
//    private var aircraftAnnotation = DJIImageAnnotation(identifier: "aircraftAnnotation")
    
    override func viewWillAppear(_ animated: Bool) {
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                let newLocationValue = newValue!.value as! CLLocation
                
                if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
//                    self.aircraftAnnotation.coordinate = newLocationValue.coordinate
                }
                
                self.latitudeLabel.text = String(format:"Lat: %.4f", newLocationValue.coordinate.latitude)
                self.longitudeLabel.text = String(format:"Long: %.4f", newLocationValue.coordinate.longitude)
                self.altitudeLabel.text = String(format:"Alt: %.1f ft", Utils.metersToFeet(newLocationValue.altitude))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            let alert = UIAlertController(title: "Location Services", message: "Location Services are not enabled.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        
        self.flightMapView.delegate = self
        self.flightMapView.mapType = .hybrid
        self.flightMapView.showsUserLocation = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    @IBAction func recordFlightPath(_ sender: Any?) {
        if self.isRecording {
            self.isRecording = false
            
            if !self.flightPathCoordinateList.isEmpty {
                self.flightPathLine = MKPolyline(coordinates: self.flightPathCoordinateList, count: self.flightPathCoordinateList.count)
                self.flightMapView.add(self.flightPathLine!)
            }
            
            self.statusLabel.text = "Current Status: Flight Plan Recorded. Ready to Fly"
            
            let alert = UIAlertController(title: "Record Successful", message: "Your flight path has been recorded. You are ready to fly", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        } else {
            self.flightPathCoordinateList.removeAll()
            self.flightPathCoordinateList.append(self.flightMapView.userLocation.coordinate)
            
            self.statusLabel.text = "Current Status: Recording Flight Plan"
            
            self.isRecording = true
        }
    }
    
    @IBAction func startFlight(_ sender: Any?) {
        if self.flightPathCoordinateList.isEmpty {
            let alert = UIAlertController(title: "Flight Path Error", message: "You must record a flight before flying.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        if self.flightPathCoordinateList.count <= 2 {
            self.missionError(message: "Your flight is too short. Please record a larger path")
            return
        }
        
        if self.flightPathCoordinateList.count >= 99 {
            self.missionError(message: "Your flight is too long. Please record a smaller path")
            return
        }
        
        let flightPlanner = FlightPlanner()
        let mission = flightPlanner.createMission(missionCoordinates: self.flightPathCoordinateList)
        
        self.loadingAlert = UIAlertController(title: "Loading", message: "Launching flight", preferredStyle: .alert)
        self.present(self.loadingAlert, animated: true)
        
        DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toUploadEvent: self, with: .main, andBlock: { (event) in
            if event.currentState == .readyToExecute {
                self.startMission(loadingAlert: self.loadingAlert)
            }
        })
        
        DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toFinished: self, with: DispatchQueue.main, andBlock: { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Mission Error", message: "Failed to finish mission", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else {
                self.statusLabel.text = "Current Status: Flight Plan Recorded. Ready to Fly"
                
                let alert = UIAlertController(title: "Mission Success", message: "The mission has finished successfully.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        })
        
        DJISDKManager.missionControl()?.waypointMissionOperator().load(mission)
        
        DJISDKManager.missionControl()?.waypointMissionOperator().uploadMission(completion: { (error) in
            if error != nil {
                self.loadingAlert.dismiss(animated: true, completion: {
                    let alert = UIAlertController(title: "Upload Error", message: "Failed to upload mission: \(error?.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                })
            }
        })
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (CLLocationCoordinate2DIsValid((locations.last?.coordinate)!)) {
            self.flightMapView.setCenter((locations.last?.coordinate)!, animated: true)
            // We don't want the map changing while the user is trying to draw on it.
            self.locationManager?.stopUpdatingLocation()
        }
    }
    
    //MARK: - MKMapViewDelegate
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        var region: MKCoordinateRegion = MKCoordinateRegion()
        region.center = self.flightMapView.userLocation.coordinate
        region.span.latitudeDelta = 0.001
        region.span.longitudeDelta = 0.001
        
        self.flightMapView.setRegion(region, animated: true)
    }
    
    // Handle the drawing of the lines and shapes
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = .red
            lineView.lineWidth = 6
            return lineView
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !self.isRecording {
            return
        }
        
        let userCoordinate = userLocation.coordinate
        let location = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let oldLocation = CLLocation(latitude: (self.flightPathCoordinateList.last?.latitude)!, longitude: (self.flightPathCoordinateList.last?.longitude)!)
        let distance = location.distance(from: oldLocation)
        
        if Utils.convertSpacingFeetToDegrees(4) < Utils.metersToFeet(distance) {
            self.flightPathCoordinateList.append(userCoordinate)
        }
    }
    
    //MARK: - Helpers
    private func startMission(loadingAlert: UIAlertController) {
        DJISDKManager.missionControl()?.waypointMissionOperator().startMission(completion: { (error) in
            if error != nil {
                loadingAlert.dismiss(animated: true, completion: {
                    let alert = UIAlertController(title: "Start Error", message: "Failed to start mission: \(error?.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                } )
            } else {
                loadingAlert.dismiss(animated: true, completion: nil)
                self.statusLabel.text = "Current Status: Flying"
            }
        })
    }
    
    private func missionError(message: String) {
        self.flightPathCoordinateList.removeAll()
        if self.flightPathLine != nil {
            self.flightMapView.remove(self.flightPathLine!)
        }
        
        let alert = UIAlertController(title: "Mission Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}
