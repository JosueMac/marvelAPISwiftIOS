//
//  ComicTableViewController.swift
//  FormConAPI
//
//  Created by Dev1 on 29/11/18.
//  Copyright © 2018 Dev1. All rights reserved.
//

import UIKit
import CoreData

class ComicTableViewController: UITableViewController {
   
   //var predicate:NSPredicate?
   var sortedResult:[NSSortDescriptor] = []
   
   
   // consulta en la BBDD // creoi una variable cuyo valor es el resultado de una funcion
   lazy var resultComics:NSFetchedResultsController<Comics> = {
      
      // genero la consulta
      let fetchComics:NSFetchRequest<Comics> = Comics.fetchRequest()
      
      // La consulta la quiero ordenada por el ID de forma descendente
      var orden = [NSSortDescriptor(key: #keyPath(Comics.id), ascending: true)]
      
      // añade a esta ordenación la ordenación que pueda añadir en la var sortedResult
      sortedResult.append(contentsOf: sortedResult)
      fetchComics.sortDescriptors = orden
      
      //Meto dentro de resultComics La busqueda(fetchPersonas Select no se que Where noseque = noseque) en la bbdd que tenemos grabada en contexto
      //en nuestro caso no vamos a agrupar sectionNameKeyPath
      // al no agrupar por nada sectionNameKeyPath: nil --> resultComics.sections?.count
      return NSFetchedResultsController(fetchRequest: fetchComics, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
      
   }()
   
   // vamos a crear un REFRESCAR PANTALLA
   lazy var refrescarPantalla:UIRefreshControl = {
      let refrescar = UIRefreshControl()
      // tiene que tener un selector
      refrescar.addTarget(self, action: #selector(self.recargarDatosAlRefrescar), for:UIControl.Event.valueChanged)
      
      refrescar.tintColor = .red
      return refrescar
   }()
   
   
   // atencion lo metemos en una funcion local
   // le añadimos @objc pq UIRefreshControl es objective C
   @objc func recargarDatosAlRefrescar() {
      refrescoSemaforo = true
      conexionMarvel()
   }
   
   var refrescoSemaforo = false
   
   
   
   
   
    override func viewDidLoad() {
      super.viewDidLoad()
      conexionMarvel()
      refreshControl = refrescarPantalla
      
      NotificationCenter.default.addObserver(forName: NSNotification.Name("CARGAOK"), object: nil, queue: OperationQueue.main) {
         _ in
         
            self.recargaDatosTabla()
         
            if self.refrescoSemaforo {
               self.refrescoSemaforo = false
               self.refrescarPantalla.endRefreshing()
            }
         
            // elimino el brur y el cargando
            guard let blur = self.navigationController?.view.viewWithTag(200) as? UIVisualEffectView, let activity = self.navigationController?.view.viewWithTag(201) as? UIActivityIndicatorView else {
                  return
            }
            blur.removeFromSuperview()
            activity.stopAnimating()
            activity.removeFromSuperview()
      }
      

      
      
      // mientras cargo pongo blur negro
      let blurEffect = UIBlurEffect(style: .dark)
      let blurredEffectView = UIVisualEffectView(effect: blurEffect)
      blurredEffectView.frame = navigationController?.view.frame ?? CGRect.zero
      blurredEffectView.tag = 200
      navigationController?.view.addSubview(blurredEffectView)
      
      // mientras cargo pongo el cargando girando
      let activity = UIActivityIndicatorView(style: .whiteLarge)
      activity.frame = navigationController?.view.frame ?? CGRect.zero
      activity.tag = 201
      activity.startAnimating()
      navigationController?.view.addSubview(activity)

    }
  

   
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
      
        return resultComics.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return resultComics.sections?.first?.numberOfObjects ?? 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      print("interior indexPath \(indexPath)")
      
         let cell = tableView.dequeueReusableCell(withIdentifier: "celda", for: indexPath) as! ComicTableViewCell
      
         let datosComic = resultComics.object(at: indexPath)
         cell.Titulo.text = datosComic.titulo
            
         var descripcionText:String = ""
         // al cargar los datos ya hemos rellenado las dexcripciones vacias, por lo que todas existen
         descripcionText += datosComic.detalle!
         let precio = datosComic.precio
         if precio > 0 {
            descripcionText += "\n"
            descripcionText += "Precio: \(precio)"
         }
      
         let descripcionTextSinHtml = descripcionText.replacingOccurrences(of: "<br>", with: "\n", options: NSString.CompareOptions.literal, range:nil)
      
         cell.miDescripcion.text = descripcionTextSinHtml
            
         if let imagenUrl = datosComic.portadaURL {
         // imagenUrl += "portrait_xlarge"
            recuperaURL(url: imagenUrl) {
               imagen in
               DispatchQueue.main.async {
                  if let resize = imagen.resizeImage(newWidth: cell.imagen.bounds.size.width) {
                     if tableView.visibleCells.contains(cell) {
                        cell.imagen.image = resize
                     }
                     datosComic.portada = resize.pngData()
                     saveContext()
                  }
               }
            }
         }

   // Configure the cell...
   return cell
   
   }


      // cuando clicamos sacamos una ventana de alerta con dos botones. uno cierra la ventana, el otro abbre el menu compartir
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let alert = UIAlertController(title: "Acción", message: "Elije qué quiere hacer", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Nada", style: .default, handler: nil))
      alert.addAction(UIAlertAction(title: "Compartir", style: .default) {
         _ in
         let dato = self.resultComics.object(at: indexPath)
         // los opcionales
         if let titulo = dato.titulo, let datoPortada = dato.portada, let portada = UIImage(data: datoPortada) {
            let items = [titulo, portada] as [Any]
            let compartir = UIActivityViewController(activityItems: items, applicationActivities: nil)
            // que quiero prohibir para uqe no se pueda compartir?
            // puede ser compartir.excludedActivityTypes = [.mail, ]
            compartir.excludedActivityTypes = [UIActivity.ActivityType.mail, UIActivity.ActivityType.postToVimeo]
            self.present(compartir, animated: true, completion: nil)
         }
      })
      present(alert, animated: true, completion: nil)
   }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
   func recargaDatosTabla() {
      do {
         try resultComics.performFetch()
      } catch {
         print("Error en la consulta en la Base de Datos\(error)")
      }
      tableView.reloadData()
   }
   
   deinit {
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name("CARGAOK"), object: nil)
   }

}
