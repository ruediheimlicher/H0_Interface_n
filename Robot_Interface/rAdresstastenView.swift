//
//  AdresstastenView.swift
//  H0_Interface
//
//  Created by Ruedi Heimlicher on 13.10.2023.
//  Copyright © 2023 Ruedi Heimlicher. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

let numrows = 3
let numcols = 4


class rAdresstaste:NSButton
{
   var row = 0
   var col = 0
   
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      let t = self.tag
      //Swift.print("rAdresstaste init tag: \(t)")
      self.action = #selector(self.report_taste)
   }
   

   
   
   @IBAction  func report_taste(_ sender: NSButton)
   {
      let status = sender.state
      let ident = self.identifier
      let tastetag = self.tag
      let tasterow:Int = (tastetag-1000) % 10
      let tastecol:Int = (tastetag-1000) / 10
      print("taste ident: \(ident) status: \(status) tag: \(tastetag) row: \(tasterow) col: \(tastecol)")
   }
}// rAdresstaste

class rAdresstastenView:NSView
{
    
   var lok:Int = 0
   //var tag = 0
   
   var hintergrundfarbe = NSColor()
   var tastenstatus:[Int] = Array(repeating: 0, count: numcols) // werte eines adressdip

   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      Swift.print("rAdresstastenView init")
      self.wantsLayer = true
      hintergrundfarbe  = NSColor.init(red: 0.45, 
                                       green: 0.45, 
                                       blue: 0.45, 
                                       alpha: 0.25)
      self.layer?.backgroundColor =  hintergrundfarbe.cgColor
      
      
      if let lokident = self.identifier 
      {
         //var lokstring:String =  lokident.rawValue
         lok = Int(lokident.rawValue) ?? 0
          // do something with viewIdent
      } else {
          // view.identifier was nil
         return
      }

      //print("subviews: : \(self.subviews)")
      //   NSColor.blue.set() // choose color
      // let achsen = NSBezierPath() // container for line(s)
      let w:Double = bounds.size.width
      let h:Double = bounds.size.height
      
      let tasteH:Double = h/Double(numrows)
      let tasteW = w/Double(numcols)
      for row in 0..<numrows
      {
         for col in 0..<numcols
         {
            let tastenrect = NSMakeRect(Double(col)*w,Double(row)*w, w,h)
            let ident = 1000 + 10 * row + col
            
            //print("adresstastenview row: \(row) col: \(col) ident: \(ident)")
            
            var taste:rAdresstaste = self.viewWithTag(ident) as! rAdresstaste
            
            let tastetag = taste.tag
            //print("tastetag: \(tastetag)")
            taste.target = self
            taste.action = #selector(self.tastenaktion)
         }
         
      }// init
      
   } 
   
    
   @IBAction func tastenaktion(_ sender: NSButton)
   {
      
      print("tastenaktion tastenstatus vor: \(tastenstatus)")
      
      
      var lokstring:String
      
      if let lokident = self.identifier {
         lokstring = lokident.rawValue
         lok = Int(lokident.rawValue) ?? 0
          // do something with viewIdent
      } else {
          // view.identifier was nil
         return
      }
      
    //  let lokident:Int = Int(self.identifier?.rawValue ?? "1111")
       
      print("tastenaktion tag: \(sender.tag) state: \(sender.state) lok: \(lok) identifier: \(Int(lokstring))")
     
      // let ident = 1000 + 10 * row + col
      let row = (sender.tag - 1000) / 10
      let col = (sender.tag - 1000) % 10
      print("tastenaktion row: \(row) col: \(col)")
      
      if sender.state == .off // Taste war on, nichts aendern
      {
         sender.state = .on
         return
      }
      
      // var checkedtaste
      for checkrow in 0..<3
      {
         let colident = 1000 + 10 * checkrow + col
         var checktaste:NSButton = self.viewWithTag(colident) as! NSButton
         print("checkrow: \(checkrow) colident: \(colident) state: \(sender.state)")
         
         if checkrow != row
         {
            
            checktaste.state = .off
         
         }
         else
         {
            tastenstatus[col] = checkrow
         }
         
      } // for checkrow
      print("tastenaktion tastenstatus nach: \(tastenstatus)")
      let userinformation = ["message":"tastenaktion", "tastenstatus": tastenstatus, "lok": lok] as [String : Any]
       
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"tastenstatus"),
              object: nil,
              userInfo: userinformation)

   }

   func setTasten(tastenarray:[Int])
   {
      print("*** Original array: \(tastenarray)")
      tastenstatus = tastenarray
      
      for col in 0..<numcols
      {
         //let tastenwert = temptastenstatus[col]
         for row in 0..<numrows
         {
            let tastenwert = tastenstatus[col]
            let ident = 1000 + 10 * row + col
            var taste:NSButton = self.viewWithTag(ident) as! NSButton
            if (row == tastenwert)
            {
               taste.state = .on
            }
            else
            {
               taste.state = .off
            }
         }
         
       }
       
   }
   
   
   
   func setAction() // nicht verwendet
   {
      let w:Double = bounds.size.width
      let h:Double = bounds.size.height
      
      print("scanAktion")
      for row in 0..<numrows
      {
         for col in 0..<numcols
         {
            
            let tastenrect = NSMakeRect(Double(col)*w,Double(row)*w, w,h)
            let ident = 1000 + 10 * row + col
            
            
            //print("adresstastenview row: \(row) col: \(col) ident: \(ident)")
            
            var taste:NSButton = self.viewWithTag(ident) as! NSButton
            
            let tastetag = taste.tag
            //print("tastetag: \(tastetag)")
            taste.target = self
            taste.action = #selector(self.tastenaktion)
            //var taste = NSButton.init(checkboxWithTitle: "", target: self,  action: #selector(scanAktion(_:)))
            //taste.setButtonType(toggle)
         }
         
      }
      
   }
   
   
    
   
}
   
   

