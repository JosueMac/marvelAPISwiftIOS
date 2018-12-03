//
//  ComicTableViewController.swift
//  FormConAPI
//
//  Created by Dev1 on 29/11/18.
//  Copyright © 2018 Dev1. All rights reserved.
//

import UIKit

class ComicTableViewController: UITableViewController {
   

    override func viewDidLoad() {
        super.viewDidLoad()
        conexionMarvel()
      
      NotificationCenter.default.addObserver(forName: NSNotification.Name("CARGAOK"), object: nil, queue: OperationQueue.main) {
         _ in
         // cuando carga los datos lo meto en la BBDD
         cargarDatosBBDD()
         
         NotificationCenter.default.addObserver(forName: NSNotification.Name("CARGABBDDOK"), object: nil, queue: OperationQueue.main) {
         _ in
         
            self.tableView.reloadData()
         
            // elimino el brur y el cargando
            guard let blur = self.navigationController?.view.viewWithTag(200) as? UIVisualEffectView, let activity = self.navigationController?.view.viewWithTag(201) as? UIActivityIndicatorView else {
                  return
            }
            blur.removeFromSuperview()
            activity.stopAnimating()
            activity.removeFromSuperview()
         }
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
  
   /*
   override func viewDidLoad() {

      let blurEffect = UIBlurEffect(style: .dark)
      let blurredEffectView = UIVisualEffectView(effect: blurEffect)
      blurredEffectView .frame = self.view.frame
      view.addSubview(blurredEffectView)
      
      let activity = UIActivityIndicatorView(style: .whiteLarge)
      activity.frame = self.view.frame
      activity.startAnimating()
      
   }
   */
   
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return datosCarga?.data.count ?? 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "celda", for: indexPath) as! ComicTableViewCell
      
         if let datosComic = datosCarga?.data.results[indexPath.row] {
         
            cell.Titulo.text = datosComic.title
            
            var descripcionText:String = ""
            if let descripcion = datosComic.description {
               descripcionText += descripcion
            }
            
            if let precio = datosComic.prices.first?.price, precio > 0 {
               descripcionText += "\n"
               descripcionText += "Precio: \(precio)"
            }
            cell.miDescripcion.text = descripcionText
            
            if let imagenUrl = datosComic.thumbnail.fullPath {
              // imagenUrl += "portrait_xlarge"
               recuperaURL(url: imagenUrl) {
                  imagen in
                  DispatchQueue.main.async {
                     if let resize = imagen.resizeImage(newWidth: cell.imagen.bounds.size.width) {
                           cell.imagen.image = resize
                        }
                     }
                  }
               }
            }


        // Configure the cell...
      return cell
   
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
   
   deinit {
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name("CARGAOK"), object: nil)
   }

}
