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
               let role:String?
            }
         }
         let creators:Creators
         let characters:Creators
      }
      let results:[Results]
   }
   let data:Data
}


// creo una carga temporal en un struct
struct comicCarga {
   let id:Int32
   let title:String
   let issueNumber:Int16
   let imagenURL:URL?
   let description:String?
   let price:Double
}

//var datosJSON:[RootJSON] = []
var datosCarga:RootJSON?
var etag:String?



// la primera vez llamo con la API
// las siguientes veces he de usar el etag personal que nos devuelve
// pero este etag hemos de poder guardarlo incluso cuando apague la app
// lo vamos a guardar en UserDefaults, pero por seguridad no es lo mas seguro

func cargar(datos:Data) {
   // para usarlo un JSON hay que decodificarlo
   let decoder = JSONDecoder()
   do {
      // meto todo en caché en un struct array
      let carga = try decoder.decode(RootJSON.self, from: datos)
      UserDefaults.standard.set(datosCarga?.etag, forKey: "etag")
      etag = datosCarga?.etag
      //print("Mi etag \(etag)")
      for dato in carga.data.results {
         let cargaTemp = comicCarga(id: Int32(dato.id), title: dato.title, issueNumber: Int16(dato.issueNumber), imagenURL: dato.thumbnail.fullPath, description: dato.description ?? "No hay descripción", price: dato.prices.first?.price ?? 0)
         
         // miro si ya está creado el personaje que ha creado ese personaje
         var personajes:[Personajes] = []
         for personajeProtagonista in dato.characters.items {
            if let existeEstePersonaje = existePersonaje(name: personajeProtagonista.name) {
               personajes.append(existeEstePersonaje)
            } else {
               let newPersonaje = Personajes(context: context)
               newPersonaje.nombre = personajeProtagonista.name
               personajes.append(newPersonaje)
            }
         }
         
         // miro si ya está creado el autor que ha creado ese autor
         var autores:[Autores] = []
         for autor in dato.creators.items {
            if let existeAutor = existeAutores(name: autor.name, role: autor.role ?? "None") {
               autores.append(existeAutor)
            } else {
               let newAutor = Autores(context: context)
               newAutor.nombre = autor.name
               newAutor.role = autor.name
               autores.append(newAutor)
            }
         }
         
         
         
         // si nos envian el mismo comic, vamos a remplazarlo
         let consulta:NSFetchRequest<Comics> = Comics.fetchRequest()
         consulta.predicate = NSPredicate(format: "id = %d", dato.id)
         do {
            let comic = try context.fetch(consulta)
            if let comicExiste = comic.first {
               comicExiste.titulo = cargaTemp.title
               comicExiste.issueNumber = cargaTemp.issueNumber
               comicExiste.portadaURL = cargaTemp.imagenURL
               comicExiste.detalle = cargaTemp.description
               comicExiste.precio = cargaTemp.price
               // en la BBDD
               comicExiste.personajes = NSOrderedSet(array:personajes)
               comicExiste.autores = NSOrderedSet(array:autores)
            } else {
               // si es nuevo ya lo guardo en Contexto
               let newComic = Comics(context: context)
               newComic.id = cargaTemp.id
               newComic.titulo = cargaTemp.title
               newComic.issueNumber = cargaTemp.issueNumber
               newComic.portadaURL = cargaTemp.imagenURL
               newComic.detalle = cargaTemp.description
               newComic.precio = cargaTemp.price
               newComic.addToPersonajes(NSOrderedSet(array:personajes))
               newComic.addToAutores(NSOrderedSet(array:autores))
            }
         } catch {
             print("Fallo en la consulta del id del Comic \(error)")
         }
      }
      saveContext()
      // ponemos un obserbador para ver cuando me ha descargado de internet. Lo escucha toda la app
      NotificationCenter.default.post(name: NSNotification.Name("CARGAOK"), object: nil)
      
   } catch {
      print("Fallo en la serialización \(error)")
   }
}


func existePersonaje(name:String) -> Personajes? {
   let consulta:NSFetchRequest<Personajes> = Personajes.fetchRequest()
   consulta.predicate = NSPredicate(format: "nombre ==[c] %@", name)
      do {
         let character = try context.fetch(consulta)
         if let valor = character.first {
            return valor
         } else {
            return nil
         }
      } catch {
         print("Fallo en la consulta de Personajes\(error)")
      }
   return nil
}

   
func existeAutores(name:String, role:String) -> Autores? {
   let consulta:NSFetchRequest<Autores> = Autores.fetchRequest()
   consulta.predicate = NSPredicate(format: "nombre ==[c] %@ AND role ==[c] %@", name, role)
      do {
         let autor = try context.fetch(consulta)
         if let valor = autor.first {
            return valor
         } else {
            return nil
         }
      } catch {
         print("Fallo en la consulta de Autores\(error)")
      }
   return nil
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
   let container = NSPersistentContainer(name: "ComicsBBDD-new")
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
