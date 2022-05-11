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
    
    //objeto que realizara la geocodificacion
    let geocoder = CLGeocoder()
    //lugar para marcar
    //Objeto que contiene los resultado de la direcccion
    //es opcional porque no tendra valor cuando aun no aya ubicacion o cuando la ubicacion no corresponda a una direccion de calle
    var placemark: CLPlacemark?
    //Realización de geocodificación inversa
    //y cambuia a true cuando se lleva a cabo una operacion de geolocalizacion
    // asi solo hacemo una solicutud ala ves si esta en true es que esta ocupado
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?

    
    //objeto que me dara las coordenadas del gps
    let locationManager = CLLocationManager()
    
    //variable para guardar la ubicacion actual del usuario
    var location: CLLocation?
    //actulizando ubicacion en falso
    var updatingLocation = false
    //ultimo error de ubicacion
    var lastLocationError: Error?

    override func viewDidLoad() {
        super.viewDidLoad()
        actulizarLabels()
        // Do any additional setup after loading the view.
    }

    func configureGetButton(){
        //si la variabla updatingLocation es versadeda es decir el manejador de ubicacion esta funcionando
        //cambiamos el titutlo de botn a parar ubicacion si no le ponemos obtener ubicacion
        if updatingLocation {
            buttonObtener.setTitle("stop obetner Ubicacion", for: .normal)
        } else {
            buttonObtener.setTitle("Obtener mi uubicacion", for: .normal)
        }
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
        
        //si authStatus esta como aprobado y/o habilitado ejecutamos el if
        //el if nos dice si la variable updatingLocation es verdadera quiere decir que el manejador de ubicaicon esta funcionando
        //entonces lo paramos
        // si no esque el manejador esta detenenido y empezamos a localizar y ponemos a nil la locacion que es nuestra ubicacion buena y el error
        if updatingLocation {
            pararManejadorUbicacion()
        } else {
            self.location = nil
            self.lastLocationError = nil
            self.placemark = nil
            self.lastGeocodingError = nil  
            iniciarManejadorUbicacion()
        }
        
        actulizarLabels()
    }
    
    //metodo para formatear el string de como mostarremos la direccion
    func string(from placemark: CLPlacemark) -> String {
        //1.-primera linea de texto para la respuesta
        var line1 = ""
        //2.-si la direccion tiene el numero de casa agregalo a la primera linea
        if let tmp = placemark.subThoroughfare {
            line1 += tmp + " "
        }
        
        //3.-si la direccion tiene el nombre de la calle agregalo
        if let tmp = placemark.thoroughfare {
            line1 += tmp
        }
        
        //4.-si la direecion tiene ciudas agregala ala segunda linea
        var line2 = "" //segunda linea de texto para la respuesta
        if let tmp = placemark.locality {
            line2 += tmp + " "
            
        }
        //si la direccion tiene estado agregalo
        if let tmp = placemark.administrativeArea {
            line2 += tmp + " "
        }
        //si la direccion tiene el codigo postal agregalo
        if let tmp = placemark.postalCode {
            line2 += tmp
        }
        
        //5.-
        return line1 + "\n" + line2
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
            
            if let placemark = placemark {
                labelDireccion.text = string(from: placemark)
            } else if performingReverseGeocoding {
                labelDireccion.text = "Buscando la direcccion...."
            } else if lastGeocodingError != nil {
                labelDireccion.text = "Error al buscar la direccion"
            } else {
                labelDireccion.text = "IDreccion no econtradas"
            }
            
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
                    //si updatingLocation es verdadera se pone buscando
                    //porque el manejador de ubicacion esta funcionando
                    //y no hay errores
                    //y depues ya bva buscar el pimrer objeto de la ubicacion
                  statusMessage = "Searching..."
                } else {
                    //si la variable es falsa poenmos este mensaje
                    //porque el manejador de ubicacion no esta funcionando
                  statusMessage = "Tap 'Get My Location' to Start"
                }
            labelMensaje.text = statusMessage
        }
        //llamamos al metodo de configurar boton
        configureGetButton()
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
        
        //verifica si el error es de unibicacion desconocida
        //que para ese error lo seguira intentando por eso salimos de la
        //ejecucion del metodo con el return
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        //en caso de un arror mas gradave y no entre al if
        //almacenara el error en la variable laslocation
        // y parara el manejador de ubicacion y actulizara los label para mostrar el error
        lastLocationError = error
        pararManejadorUbicacion()
        actulizarLabels()
    }
    
    //se ejecuta para estar actulizando la poscion del gps siempre se estara ejecutando mientras la app esta funcionandos
    //se eejecutara despues de aver presionado el boton de obntener ubucacion
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let nuevaUbicacion = locations.last!
        print("Actulizo ubicaciones con la ultima ubicacion es \(nuevaUbicacion)")
        
        //1.-Aqui ignoara las ubicaciones almacenas en cache si son antiguas y salimos del metodo con el return
        //y se vuelve a retomar una lectura valida
        if nuevaUbicacion.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        //2.-si la presion horizontal son negativas se ingnoran y se sale del metodo y se veulve a retomar una lectura valida
        if nuevaUbicacion.horizontalAccuracy < 0 {
            return
        }
        
        //3.-si es la primera lectura de la ubiacion location == nil o la nueva ubicacion es mas presisa que la anterior
        //entramos al if para ejecutar el paso 4 si no no salimos y se vuvle a hacer una lectura valida
        if self.location == nil || self.location!.horizontalAccuracy > nuevaUbicacion.horizontalAccuracy {
            //4.-//borrar cualquier error anterios y almcena la nueva ubicacion mas presisa en la ubicacion global
            self.lastLocationError = nil
            self.location = nuevaUbicacion
            
            //5.-si la presion de la nueva ubicacion es mejor que la presion deseada o iguual paramos el manejador de ubicacion y giardamos esa ubicacion
            if nuevaUbicacion.horizontalAccuracy <= self.locationManager.desiredAccuracy {
                print("*** We are done")
                pararManejadorUbicacion()
            }
        }
        
//        self.location = nuevaUbicacion
//        self.lastLocationError = nil
        actulizarLabels()
        
        //vemos si esta en false es que no esta haciendo ninfuna solicitud a lso servios de apple y podemos empesar
        //por el otro lado si es true quiere decir que esta ocupado por eso dentro del cierre los cambiamos a true
        //y asi esta ocupado
        if !self.performingReverseGeocoding {
            print("*** Going to geocoder  vammos a geocodificar la inversa")
            //esta ocupado
            self.performingReverseGeocoding = true
            
            
            self.geocoder.reverseGeocodeLocation(nuevaUbicacion) { placemarks, error in
                self.lastGeocodingError = error
                if error == nil, let placers = placemarks, !placers.isEmpty {
                    self.placemark = placers.last!
                } else {
                    self.placemark = nil
                }
                
                self.performingReverseGeocoding = false
                self.actulizarLabels()
                
                
//                if let error = error {
//                    print("Error de geocodificacion inverso \(error.localizedDescription)")
//                    return
//                }
//                if let placers = placemarks {
//                    print("*** lugares encontrados \(placers) ")
//                }
            }//fin del geocoder
        }//fin del if de gecodificacion inversa
    }
    
    
    
    
}

