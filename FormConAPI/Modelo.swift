//
//  File.swift
//  FormConAPI
//
//  Created by Dev1 on 30/11/18.
//  Copyright © 2018 Dev1. All rights reserved.
//

import Foundation
import UIKit
import CoreData



// voy a crear el JSON interno, con el JSON que nos devuelve Marvel
struct RootJSON:Codable {
   let etag:String
   struct Data:Codable {
      let count:Int
      struct Results:Codable {
         let id:Int
         let title:String
         let issueNumber:Int
         let variantDescription:String
         let description:String?
         
         struct Prices:Codable {
            let type:String
            let price:Double
         }
         let prices:[Prices]
         
         struct Thumbnail:Codable {
            let path:URL
            // extension es una palabra del sistema, no lo podemos usar.
            // por lo que le digo que use imageExtension cuando se lo encuentre
            let imageExtension:String
            enum CodingKeys:String, CodingKey {
               case path
               case imageExtension = "extension"
            }
            var fullPath:URL? {
               var pathComponents = URLComponents(url: path, resolvingAgainstBaseURL: false)
               pathComponents?.scheme = "https"
               return pathComponents?.url?.appendingPathExtension(imageExtension)
            }
         }
         // vamos a intentar crea directamente la URL de la imagen, y cambiar http por https, para que IOS nos permita la llamada

         let thumbnail:Thumbnail
         
         struct Creators:Codable{
            let items:[Items]
            struct Items:Codable {
               let name:String
               let role:String
            }
         }
         let creators:Creators
         
      }
      let results:[Results]
   }
   let data:Data
}

//var datosJSON:[RootJSON] = []
var datosCarga:RootJSON?
var etag:String?



// la primera vez llamo con la API
// las siguientes veces he de usar el etag personal que nos devuelve
// pero este etag hemos de poder guardarlo incluso cuando apague la app
// lo vamos a guardar en UserDefaults, pero por seguridad no es lo mas seguro
func cargar(datos:Data) {
   let decoder = JSONDecoder()
   do {
      // meto todo en caché en un struct tipo RootJSON q he creado antes
      datosCarga = try decoder.decode(RootJSON.self, from: datos)
      UserDefaults.standard.set(datosCarga?.etag, forKey: "etag")
      etag = datosCarga?.etag
      //print("Mi etag \(etag)")
      
      // ponemos un obserbador para ver cuando me ha descargado de internet. Lo escucha toda la app
      NotificationCenter.default.post(name: NSNotification.Name("CARGAOK"), object: nil)
      
   } catch {
      print("Fallo en la serialización \(error)")
   }
}

/**
 Rellena una BBDD xc data modelo con los datos recogidos del RootJSON
 */
func cargarDatosBBDD() {
   // miramos si es la carga inicial y hay mas de 0 Comics en la base de datos
   let consultaComics:NSFetchRequest<Comics> = Comics.fetchRequest()
   let numComics = (try? context.count(for: consultaComics)) ?? 0
   if numComics > 0 {
      return
   }
   
   guard datosCarga?.data.count == 0 else {
      return
   }
   do {
     // let decoder = JSONDecoder()
     // let datosBruto = try Data(datosCarga)
      let datosStruct = datosCarga
      for dato in (datosStruct?.data.results)! {
         let comic = Comics(context: context)
         comic.id = Int16(dato.id)
         comic.titulo = dato.title
         comic.detalle = dato.description
         if let precio = dato.prices.first?.price, precio > 0 {
            comic.precio = (dato.prices.first?.price)!
         } else {
            comic.precio = 0
         }
         

 /* paso de la imagen de momento
            if let imagenUrl = dato.thumbnail.fullPath {
               // imagenUrl += "portrait_xlarge"
               recuperaURL(url: imagenUrl) {
                  imagen in
                  DispatchQueue.main.async {
                     if let resize = imagen.resizeImage(newWidth: cell.imagen.bounds.size.width) {
                        cell.imagen.image = resize
                        comic.portada = resize
                     }
                  }
               }
            }
         }
 */
         
         /*
         // miramos si jobtitle existe, y hemos de hacer una consulta
         // para hacer busquedas con NSPredicate, buscar que es %@ (string) o %d  o %F en internet
         let consultaPuesto:NSFetchRequest<Departamentos> = Departamentos.fetchRequest()
         consultaPuesto.predicate = NSPredicate (format: "jobtitle = %@", dato.jobtitle)
         // y ahora usamos la consulta
         if let arrayDePuestos = try? context.fetch(consultaPuesto), let puesto = arrayDePuestos.first {
            persona.jobtitle = puesto
         } else {
            let puesto = Departamentos(context: context)
            puesto.jobtitle = dato.jobtitle
            persona.jobtitle = puesto
         }
 */
      }
   }
   NotificationCenter.default.post(name: NSNotification.Name("CARGABBDDOK"), object: nil)
   saveContext()
}



func grabarDatos() {
   /*
   let ruta = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("MOCK_DATA.json", isDirectory: false)
   do {
      let encoder = JSONEncoder()
      let datosBruto = try encoder.encode(datos)
      try datosBruto.write(to: ruta, options: .atomic)
   } catch {
      print("Error en la serialización \(error)")
   }
   */
}


//////////////////////////////////// BBDD //////////////////////////////////////

// cargo mi base de datos que he creado en el fichero Data Model (.xcdatamodeld)

var persistenceContainer:NSPersistentContainer = {
   let container = NSPersistentContainer(name: "COMICSBBDD")
   container.loadPersistentStores { (storeDescripcion, error) in
      if let error = error as NSError? {
         fatalError("Error inicialización de Base de Datos")
      }
   }
   return container
}()

// creo el CONTEXTO de la BBDD
// persistenceContainer es el Disco Duro

var context:NSManagedObjectContext {
   return persistenceContainer.viewContext
}

/**
 Si hay cambios en el Contexto, guardo el Contexto del tipo NSManagedObjectContext en la BBDD en Disco.
 En el que contexto sería: var context:NSManagedObjectContext { return persistenceContainer.viewContext }
 */
func saveContext() {
   if context.hasChanges {
      do {
         try context.save()
      } catch {
         print("Error en la grabación en Base de Datos. \(error)")
      }
   }
}
