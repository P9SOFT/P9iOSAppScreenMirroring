//
//  ViewController.swift
//  ScreenMirroringServer
//
//  Created by Sung Jin Kim on 3/21/21.
//

import UIKit

class ViewController: UIViewController {

    fileprivate let bindServerKey = "bindServerKey"
    fileprivate let wsdogma = HJWebsocketDogma(limitFrameSize: 8180, limitMessageSize: 1024*1024*10)

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.tcpCommunicateManagerHandler(notification:)), name: NSNotification.Name(rawValue: HJAsyncTcpCommunicateManagerNotification), object: nil)
    }

    
    
    func serverBind(_ port: Int) {
        
        // set key to given server address and port
        let serverInfo = HJAsyncTcpServerInfo.init(address: "localhost", port: port as NSNumber)
        HJAsyncTcpCommunicateManager.default().setServerInfo(serverInfo, forServerKey: bindServerKey)
        
        // request connect and regist each handlers.
        HJAsyncTcpCommunicateManager.default().bind(bindServerKey, backlog: 4, dogma: wsdogma, bind: { (flag, key, header, body) in
            if flag == true { // bind ok
            } else { // bind failed
            }
        }, accept: { (flag, key, header, body) in
            
        }, receive: { (flag, key, header, body) in
            if flag == true, let clientKey = key, let dataFrame = header as? HJWebsocketDataFrame { // receive ok
                if let receivedText = dataFrame.data as? String {
                    print("- clientKey: \(clientKey),    receivedText: \(receivedText)")
                } else if let receivedData = dataFrame.data as? Data, let _ = UIImage(data: receivedData) {
                    print("- received image.")
                }
            }
        }, disconnect: { (flag, key, header, body) in
            
        }, shutdown: { (flag, key, header, body) in
            if flag == true { // shutdown ok
            }
        })
    }
    
    func serverShutdown() {
        // request shutdown
        HJAsyncTcpCommunicateManager.default().shutdownServer(forServerKey: bindServerKey)
    }

    
    func serverSend(_ text: String) {
        let headerObject = HJWebsocketDataFrame(text: text, supportMode: .server)
        
        // broadcast text
        HJAsyncTcpCommunicateManager.default().broadcastHeaderObject(headerObject, bodyObject: nil, toServerKey: bindServerKey)
    }
    
    @objc func tcpCommunicateManagerHandler(notification:Notification) {
        guard let userInfo = notification.userInfo, let serverKey = userInfo[HJAsyncTcpCommunicateManagerParameterKeyServerKey] as? String, let eventValue = userInfo[HJAsyncTcpCommunicateManagerParameterKeyEvent] as? Int, let event = HJAsyncTcpCommunicateManagerEvent(rawValue: eventValue) else {
            return
        }
        
        let clientKey = userInfo[HJAsyncTcpCommunicateManagerParameterKeyClientKey] as? String ?? "--"
        switch event {
        case .connected:
            print("- server \(serverKey) client \(clientKey) connected.")
        case .disconnected:
            print("- server \(serverKey) client \(clientKey) disconnected.")
        case .sent:
            print("- server \(serverKey) client \(clientKey) sent.")
        case .sendFailed:
            print("- server \(serverKey) client \(clientKey) send failed.")
        case .received:
            print("- server \(serverKey) client \(clientKey) received.")
        case .binded:
            print("- server \(serverKey) binded.")
        case .accepted:
            print("- server \(serverKey) client \(clientKey) accepted.")
        case .shutdowned:
            print("- server \(serverKey) shutdowned.")
        default:
            break
        }
    }

}

