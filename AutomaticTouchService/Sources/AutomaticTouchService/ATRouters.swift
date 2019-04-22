//
//  ATRouters.swift
//  AutomaticTouchService
//
//  Created by renlei on 2019/4/3.
//

import Foundation
import PerfectHTTP
import PerfectWebSockets


func getATRoutes() -> Routes {
    
    var routes = Routes()
    
    routes.add(method: .get, uri: "at", handler: {  request, response in
        
        WebSocketHandler(handlerProducer: { (request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
            
            if protocols.contains("atClient") {
                return getATClientHandler(request: request)
            }
            return nil
            
        }).handleRequest(request: request, response: response)
    })
    
    return routes
}



var clientMap = NSMapTable<NSString, ATClientHandler>.strongToWeakObjects()

func getATClientHandler(request: HTTPRequest) ->  ATClientHandler {
    
    let handler = ATClientHandler()
    if let secWebSocketKey = request.header(.custom(name: "sec-websocket-key")) {
        clientMap.setObject(handler, forKey: secWebSocketKey as NSString)
        handler.secWebSocketKey = secWebSocketKey
        print(secWebSocketKey)
    }
    return handler
}


class ATClientHandler: WebSocketSessionHandler {
    
    let socketProtocol: String? = "atClient"
    var secWebSocketKey: String?
    weak var socket : WebSocket?
    
    func handleSession(request: HTTPRequest, socket: WebSocket) {
        
        self.socket = socket
        
        socket.readStringMessage { string, op, fin in
            
            guard let string = string else {
                socket.close()
                return
            }
      
            let enumerator = clientMap.keyEnumerator()
            
            while let secWebSocketKey = enumerator.nextObject() as? String {
               
                if secWebSocketKey != self.secWebSocketKey {
                    
                    if let clent = clientMap.object(forKey: secWebSocketKey as NSString) {
                        
                        clent.socket?.sendStringMessage(string: string, final: true, completion: {
                            
                        })
                    }
                }
            }

            print("Client Read msg: \(string) op: \(op) fin: \(fin)")
            self.handleSession(request: request, socket: socket)
        }
    }
}
