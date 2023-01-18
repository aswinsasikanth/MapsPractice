//
//  ViewController.swift
//  MapsPractice
//
//  Created by Aswin Sasikanth Kanduri on 2023-01-18.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var routeButton: UIButton!
    
    var routeLine: MKPolyline!
    var locationManager = CLLocationManager()
    var destinationCount = 0
    var destination: CLLocationCoordinate2D!
    var cities = [City]()
    var touchPoints = [CGPoint]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Hide route button and display when route is selected
        routeButton.isHidden = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        map.isZoomEnabled = false
        map.showsUserLocation = false
        map.delegate = self
        
        addDoubleTap()
    }
    
    
    func addDoubleTap() -> () {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 2
        map.addGestureRecognizer(doubleTap)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer){
        let touchPoint = sender.location(in: map)
        let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
        let annotation = MKPointAnnotation()
        
        touchPoints.append(touchPoint)
        destinationCount += 1
        
        //make route button visible for action once more than one location is selected
        
        if destinationCount > 1 {
            routeButton.isHidden = false
        }
        
        if destinationCount <= 3 {
            annotation.title = "Destination \(destinationCount)" //WHAT IS THIS
            annotation.coordinate = coordinate
            map.addAnnotation(annotation)
            
            let city = City(title: "Destination\(destinationCount)", subtitle: "Destination\(destinationCount)", coordinate: CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude))
            cities.append(city)
        }
        
        if destinationCount == 3 {
            cities.append(cities[0])
            addPolyline()
            addPolygon()
            calculateDistance(cities: cities)
        }
    }
        
        func addPolyline() -> () {
            let coordinates = cities.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            map.addOverlay(polyline)
        }
        
        func addPolygon() {
            let coordinates = cities.map{ $0.coordinate}
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            map.addOverlay(polygon)
        }
        
        
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let userLocation = locations[0]
            
            let latitude = userLocation.coordinate.latitude
            let longitude = userLocation.coordinate.longitude
            
            print(userLocation)
            
            displayLocation(latitude: latitude, longitude: longitude)
            
        }
        
        func displayLocation(latitude: CLLocationDegrees,
                             longitude: CLLocationDegrees) -> () {
            let latDelta: CLLocationDegrees = 0.05
            let lngDelta: CLLocationDegrees = 0.05
            
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: location, span: span)
            
            map.setRegion(region, animated: true)
        }
        
        
    func calculateDistance(cities: [City]) {
        var nextIndex: Int
        
        for index in 0...2 {
            if index == 2 {
                nextIndex = 0
            }
            else {
                nextIndex = index + 1
            }
            let startPoint = CLLocation(latitude: cities[index].coordinate.latitude, longitude: cities[index].coordinate.longitude)
            let endPoint = CLLocation(latitude: cities[nextIndex].coordinate.latitude, longitude: cities[nextIndex].coordinate.longitude)
            
            let distance = startPoint.distance(from: endPoint) / 1609.344
            
            let coordinate1 = map.convert(touchPoints[index], toCoordinateFrom: map)
            let coordinate2 = map.convert(touchPoints[nextIndex], toCoordinateFrom: map)
            let midPointLat = (coordinate1.latitude + coordinate2.latitude) / 2
            let midPointLong = (coordinate1.longitude + coordinate2.longitude) / 2
            let annotation = MKPointAnnotation()

            annotation.title = String(format: "%.01fmi", distance)
            annotation.coordinate = CLLocationCoordinate2DMake(midPointLat, midPointLong)
            map.addAnnotation(annotation)
        }
    }
    @IBAction func drawRoute(_ sender: UIButton) {
        map.removeOverlays(map.overlays)
        
        let sourcePlaceMark = MKPlacemark(coordinate: locationManager.location!.coordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        // request a direction
        let directionRequest = MKDirections.Request()
        
        // assign the source and destination properties of the request
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        // transportation type
        directionRequest.transportType = .automobile
        
        // calculate the direction
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            // create the route
            let route = directionResponse.routes[0]
            // drawing a polyline
            self.map.addOverlay(route.polyline, level: .aboveRoads)
            
            // define the bounding map rect
            let rect = route.polyline.boundingMapRect
            self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            
           self.map.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.systemGreen
            rendrer.lineWidth = 3
            
            if routeLine != nil {
                rendrer.strokeColor = UIColor.systemBlue
                rendrer.lineWidth = 5
            }
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.systemGreen
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}


    

