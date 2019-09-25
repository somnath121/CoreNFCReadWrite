//
//  ViewController.swift
//  NFCIOS
//
//  Created by SOMNATH CHATTERJEE on 25/9/19.
//  Copyright © 2019 Somnath. All rights reserved.
//

import UIKit
#if canImport(CoreNFC)
import CoreNFC
#endif

class ViewController: UIViewController, NFCNDEFReaderSessionDelegate, UITextFieldDelegate  {
    
    @IBOutlet weak var lblTagData: UILabel!
    var readingSession : NFCNDEFReaderSession?
    var writingSession : NFCNDEFReaderSession?

    @IBOutlet weak var txtFieldContent: UITextField!
    var intent: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.lblTagData.text = ""

    }
    
    @IBAction func btnWriteDidTap(_ sender: Any) {
        intent = "Write"
        beginWriting()
    }
    @IBAction func btnReadTagDidTap(_ sender: Any) {
        intent = "Read"
        beginReading()
    }
    
    
    //MARK:- UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    //MARK:- NFC Session
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("messages \(messages)")
    }
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("error \(error)")
    }
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]){
        let tag = tags.first!
               session.connect(to: tag) { (error: Error?) in
                   if error != nil {
                       session.restartPolling()
                   }
               }
        
               tag.queryNDEFStatus() { (status: NFCNDEFStatus, capacity: Int, error: Error?) in
                   
                   if error != nil {
                       self.writingSession!.invalidate(errorMessage: "Fail to determine NDEF status.  Please try again.")
                       return
                   }
                if(self.intent == "Write"){
                    let textToWrite = self.txtFieldContent.text!
                    let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(string: textToWrite, locale: Locale(identifier: "En"))
                   let myMessage = NFCNDEFMessage(records: [textPayload!])
               
                   if status == .readOnly {
                    self.writingSession!.invalidate(errorMessage: "Tag is not writable.")
                   } else if status == .readWrite {
                       tag.writeNDEF(myMessage) { (error: Error?) in
                           if error != nil {
                               self.writingSession!.invalidate(errorMessage: "Update tag failed. Please try again.")
                           } else {
                               self.writingSession!.alertMessage = "Update success!"
                                DispatchQueue.main.async {
                                    self.lblTagData.text = ""
                                }
                                self.writingSession!.invalidate()
                           }
                       }
                   } else {
                        self.writingSession!.invalidate(errorMessage: "Tag is not NDEF formatted.")
                   }
               }
        else{
            print("Read")
            print("messages \(tag)")
                tag.readNDEF { (msg, err) in
                   // print(msg?.records[0].payload)
                    let str = msg?.records[0].wellKnownTypeTextPayload().0!
                    DispatchQueue.main.async {
                        self.lblTagData.text = str
                    }
                    
                    session.alertMessage = str!
                    self.readingSession?.invalidate()
                }
            }
        }
    }
    

    

    func beginWriting() {
        self.writingSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead:
            true)
        self.writingSession?.alertMessage = "Hold your iPhone near the tag to begin transaction."
        self.writingSession?.begin()
    }
    
    func beginReading() {
        self.readingSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead:
            true)
        self.readingSession?.alertMessage = "Hold your iPhone near the tag to begin transaction."
        self.readingSession?.begin()
    }
}

extension Substring {
    func toString() -> String {
        return String(self)
    }
}
#if canImport(CoreNFC)
func string(fromTypeNameFormat: NFCTypeNameFormat) -> String {
    switch fromTypeNameFormat {
    case .empty:
        return "empty"
    case .nfcWellKnown:
        return "nfcWellKnown"
    case .media:
        return "media"
    case .absoluteURI:
        return "absoluteURI"
    case .nfcExternal:
        return "nfcExternal"
    case . unknown:
        return "unknown"
    case .unchanged:
        return "unchanged"
    }
}
#endif
