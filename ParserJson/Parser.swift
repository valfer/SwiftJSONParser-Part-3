//
//  Parser.swift
//  ParserJson
//
//  Created by Valerio Ferrucci on 11/11/14.
//  Copyright (c) 2014 Valerio Ferrucci. All rights reserved.
//

import Foundation

let kMaxBlockingError = 100     // should be class var, but not yet implemented

class Parser {

    //MARK: PUBLIC (internal)
    enum ReaderResult {
        case Value(NSData)
        case Error(NSError)
    }
    
    enum Result {
        case Value(Photo)
        case Error(NSError)
    }

    // the reader is a func that receive a completion as parameter (called on finish)
    typealias ParserReader = (ReaderResult->())->()
    typealias ParserCallback = (Result)->Bool
    
    func start(reader : ParserReader, parserCallback : ParserCallback) {
        
        var error : NSError?
        
        // read the file
        reader() { (result : ReaderResult)->() in
            
            switch result {
            case let .Error(readError):
                error = readError
                
            case let .Value(fileData):
                error = self.handleData(fileData, parserCallback)
            }
            
            if let _error = error {
                parserCallback(Parser.Result.Error(_error))
            }
        }
    }
    
    //MARK: PRIVATE
   
    private func handleData(data : NSData, parserCallback : ParserCallback) -> NSError? {
        
        var error : NSError?
        let json : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error)
        
        if let _json = json as? [AnyObject] {
            
            for jsonItem in _json {
                
                if let _jsonItem = jsonItem >>> DictionaryFromJSON {
                    var ok = false
                    var toStop = false
                    if let _titolo = _jsonItem["titolo"] >>> StringFromJSON {
                        if let _autore = _jsonItem["autore"] >>> StringFromJSON {
                            if let _latitudine = _jsonItem["latitudine"] >>> DoubleFromJSON {
                                if let _longitudine = _jsonItem["longitudine"] >>> DoubleFromJSON {
                                    if let _data = _jsonItem["data"] >>> StringFromJSON {
                                        if let _descr = _jsonItem["descr"] >>> StringFromJSON {
                                            
                                            let photo = Photo(titolo: _titolo, autore: _autore, latitudine: _latitudine, longitudine: _longitudine, data: _data, descr: _descr)
                                            toStop = parserCallback(Result.Value(photo))
                                            if toStop {
                                                break
                                            }
                                            ok = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if (!ok) {
                        // don't override error
                        let photoError = NSError(domain: "Parser", code: kMaxBlockingError+1, userInfo: [NSLocalizedDescriptionKey:"Errore su un elemento dell'array"])
                        parserCallback(Result.Error(photoError))
                    }
                }
            }
        } else {
            error = NSError(domain: "Parser", code: kMaxBlockingError, userInfo: [NSLocalizedDescriptionKey:"Json is not an array of AnyObjects"])
        }
        
        return error
    }

    private func StringFromJSON(ao : AnyObject) -> String? {
        return ao as? String
    }
    private func DoubleFromJSON(ao : AnyObject) -> Double? {
        return ao as? Double
    }
    private func DictionaryFromJSON(ao : AnyObject) -> [String: AnyObject]? {
        return ao as? [String: AnyObject]
    }

}