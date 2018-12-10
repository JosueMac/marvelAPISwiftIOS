//
//  tools.swift
//  FormConAPI
//
//  Created by Dev1 on 29/11/18.
//  Copyright © 2018 Dev1. All rights reserved.
//

import Foundation
import CommonCrypto
import UIKit

// copio las API de Marvel
let publicKey = "6bca5f51112ab9a623d6540f66a52b8a"
let privateKey = "2709d9ee645eea45543821c60ca3acbdb5ad3089"

var baseURL = URL(string: "https://gateway.marvel.com/v1/public")!


/*
 Instrucciones de developed.marvel.com
 Authentication for Server-Side Applications
 Server-side applications must pass two parameters in addition to the apikey parameter:
 
 ts - a timestamp (or other long string which can change on a request-by-request basis)
 hash - a md5 digest of the ts parameter, your private key and your public key (e.g. md5(ts+privateKey+publicKey)
 For example, a user with a public key of "1234" and a private key of "abcd" could construct a valid call as follows:
 http://   gateway.marvel.com/v1/public/comics?ts=1&apikey=1234&hash=ffd275c5130566a2916217b101f26150
 (the hash value is the md5 digest of 1abcd1234)
*/
func conexionMarvel() {
   // pillamos un num aleatorio con los segundos de reloj
   //let ts = getDataTime()
   let ts = "\(Date().timeIntervalSince1970)"
   let valorFirmar = ts+privateKey+publicKey
   let queryts = URLQueryItem(name: "ts", value: ts)
   let queryApiKey = URLQueryItem(name: "apikey", value: publicKey)
   let queryHash = URLQueryItem(name: "hash", value: valorFirmar.MD5)
   let queryLimit = URLQueryItem(name: "limit", value: "100")
   // le pido solo comics de tapa dura
   // let queryOrder = URLQueryItem(name: "orderBy", value: "onsaleDate")
   // le pido solo comics de tapa dura
   //let queryFormat = URLQueryItem(name: "format", value: "hardcover")

   
   var url = URLComponents()
   url.scheme = baseURL.scheme
   
   url.host = baseURL.host
  
   url.path = baseURL.path
   
   url.queryItems = [queryts, queryApiKey, queryHash, queryLimit]
  
   
   // inicializamos la conexión
   let session = URLSession.shared
   
   // pedimos la petición // el comics, es el  de comics?ts=1&apikey=1234&hash=ffd275c51305....
   var request = URLRequest(url: url.url!.appendingPathComponent("comics"))
   print(url.url!.appendingPathComponent("comics"))
   print("ts - \(ts)")
   request.httpMethod = "GET"
   request.addValue("*/*", forHTTPHeaderField: "Accept")
   
   // las siguentes veces que llamemos con nuestro etag, Marvel nos pide que añadamos esto
   //   if let etag = etag {
   //      request.addValue(etag, forHTTPHeaderField: "If-None-Match")
   //   }
   
   session.dataTask(with: request){
      (data, response, error) in guard let data = data , let response = response as? HTTPURLResponse, error == nil else {
         if let error = error {
            print("Error en la comunicación \(error)")
         }
         return
      }
      if response.statusCode == 200 {
         cargar(datos: data)
         print ("cargando Datos")
      } else {
         print("statusCode \(response.statusCode)")
      }
   }.resume()
}

// nos piden una fecha actual para hacer el ts - a timestamp del envío
// creamos un string con un num que siempre es diferente cada vez que hacemos la peticion
func getDataTime() -> String {
   let fecha = Date()
   let formatear = DateFormatter()
   formatear.dateFormat = "ddMMyyyyhhmmss"
   return formatear.string(from: fecha)
}



// creamos el calculo MD5 que nos pide marvel
// creo un array de bytes lleno de 0000 de longitud MD5
// y luego desde otra tabla de la misma longitud con nuestra key
// sustituyendo los 0000 por mi Key
extension String {
   var MD5:String? {
      guard let messageData = self.data(using: .utf8) else {
         return nil
      }
      var datoMD5 = Data(count: Int(CC_MD5_DIGEST_LENGTH))
      _ = datoMD5.withUnsafeMutableBytes {
         bytes in
         messageData.withUnsafeBytes { messageBytes in
            CC_MD5(messageBytes, CC_LONG(messageData.count), bytes)
         }
      }
      var MD5String = String()
      for c in datoMD5 {
         MD5String += String(format: "%02x", c)
      }
      return MD5String
   }
}


// conseguir la imagen de Internet
func recuperaURL(url:URL, callback:@escaping (UIImage) -> Void) {
   let conexion = URLSession.shared
   conexion.dataTask(with: url) { (data, response, error) in
      guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
         if let error = error {
            
            print("Error en la conexión de red \(error.localizedDescription) decargando \(url)")
         }
         return
      }
      if response.statusCode == 200 {
         if let imagen = UIImage(data: data) {
            callback(imagen)
         }
      }
      }.resume()
}


extension UIImage {
   func resizeImage(newWidth:CGFloat) -> UIImage? {
      let scale = newWidth / self.size.width
      let newHeight = self.size.height * scale
      let newSize = CGSize(width: newWidth, height: newHeight)
      UIGraphicsBeginImageContext(newSize)
      self.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return newImage
   }
}
