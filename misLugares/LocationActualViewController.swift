//
//  ViewController.swift
//  misLugares
//
//  Created by Ricardo Roman Landeros on 02/05/22.
//

import UIKit
import CoreLocation

class LocationActualViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var labelMensaje: UILabel!
    @IBOutlet weak var labelLatitude: UILabel!
    @IBOutlet weak var labelLongitud: UILabel!
    @IBOutlet weak var labelDireccion: UILabel!
    @IBOutlet weak var botonEtiqueta: UIButton!
    @IBOutlet weak var buttonObtener: UIButton!
    
    //objeto que me dara las coordenadas del gps
    let locationManager = CLLocationManager()
    
    //variable para guardar la ubicacion actual del usuario
    var location: CLLocation?
    //actulizando ubicacion en falso
    var updatingLocation = false
    //ultimo herror de ubicacion
    var lastLocationError: Error?

    override func viewDidLoad() {
        super.viewDidLoad()
        actulizarLabels()
        // Do any additional setup after loading the view.
    }

    
    // MARK: - Actions
    @IBAction func obtenerUbicacion() {
        
        //vemos el estatus de la autorizacion
        let authStatus = locationManager.authorizationStatus
        //si el estatus de la autorizacion esta indeterminado
        //pedimos autizacion para cuando solo este en uso
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted {
            mostrarAlertaDelServicioUbicacion()
            return
        }
        
        iniciarManejadorUbicacion()
        actulizarLabels()
    }
    
    func actulizarLabels(){
        //Si podemos desenvolver el optional de location entonces hacemos esto si no haceno lo del else
        if let location = location {
            labelLatitude.text = String(
                format: "%.8f",
                location.coordinate.latitude)
            labelLongitud.text = String(
                format: "%.8f",
                location.coordinate.longitude)
            botonEtiqueta.isHidden = false
            labelMensaje.text = ""
        } else {
            labelLatitude.text = ""
            labelLongitud.text = ""
            labelDireccion.text = ""
            botonEtiqueta.isHidden = true
            let statusMessage: String
                if let error = lastLocationError as NSError? {
                  if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                  } else {
                    statusMessage = "Error Getting Location"
                  }
                } else if !CLLocationManager.locationServicesEnabled() {
                  statusMessage = "Location Services Disabled"
                } else if updatingLocation {
                  statusMessage = "Searching..."
                } else {
                  statusMessage = "Tap 'Get My Location' to Start"
                }
            labelMensaje.text = statusMessage
        }
    }
    
    func mostrarAlertaDelServicioUbicacion() {
        let alert = UIAlertController(title: "Servicio de ubicacion desabilitado", message: "Por favor habilite lo servicios de ubicacio en settings", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func iniciarManejadorUbicacion(){
        if CLLocationManager.locationServicesEnabled() {
            //aqui le decimos que este controlador queire firmar elprotocolo y sera su delegado
            //haciendo lo que en el protocolo dice para obtener la ubicacion
            locationManager.delegate = self
            //le decimos que queremos preccion de 10 metros
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            //iniciamos la lectura de la ubicacion y que se vaya actualizando
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func pararManejadorUbicacion(){
        if updatingLocation {
            self.locationManager.stopUpdatingLocation()
            self.locationManager.delegate = nil
            updatingLocation = false
        }
    }

    
    // MARK: - CLLocationManagerDelegate metodos del delgado
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Fallo con el error \(error.localizedDescription)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        pararManejadorUbicacion()
        actulizarLabels()
    }
    
    //se ejecuta para estar actulizando la poscion del gps siempre se estara ejecutando mientras la app esta funcionandos
    //se eejecutara despues de aver presionado el boton de obntener ubucacion
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let nuevaUbicacion = locations.last!
        print("Actulizo ubicaciones con la ultima ubicacion es \(nuevaUbicacion)")
        
        self.location = nuevaUbicacion
        self.lastLocationError = nil
        actulizarLabels()
    }
}

