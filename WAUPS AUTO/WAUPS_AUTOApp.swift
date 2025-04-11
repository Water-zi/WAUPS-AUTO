//
//  WAUPS_AUTOApp.swift
//  WAUPS AUTO
//
//  Created by 唐梓皓 on 2025/4/5.
//

import SwiftUI
import CryptoKit

@main
struct WAUPS_AUTOApp: App {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    print("App opened with URL: \(url)")
                    
                    let publicKeyData = Data(base64Encoded: "YYa4IDnDm+pfjDi8rSvcV2603y4dJy7K8E3mExFDUPscb018V9sLT7Dm4fMco0Ty6+Q+nOYzyUwTyvXwnvoMvg==")!
                    let publicKey = try! P256.Signing.PublicKey(rawRepresentation: publicKeyData)
                    
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let queryItems = components?.queryItems ?? []
                    
                    let timestamp = queryItems.first(where: { $0.name == "timestamp" })?.value ?? ""
                    let action = queryItems.first(where: { $0.name == "action" })?.value ?? ""
                    let signature = queryItems.first(where: { $0.name == "signature" })?.value ?? ""
                    
                    let message = "timestamp=\(timestamp)&action=\(action)"
                    
                    if verify(signature: signature, message: message, publicKey: publicKey) {
                        if action == "shutdown" {
                            if viewModel.shutdownMacAsync() {
                                viewModel.startCountdown()
                            }
                        }
                    } else {
                        viewModel.tipsText = "请检查是否有软件在恶意调用指令"
                        viewModel.tipsTextColor = .red
                    }
                }
        }
    }
    
    func verify(signature: String, message: String, publicKey: P256.Signing.PublicKey) -> Bool {
        guard let signatureData = Data(base64Encoded: signature),
              let signature = try? P256.Signing.ECDSASignature(derRepresentation: signatureData) else {
            return false
        }
        let messageData = message.data(using: .utf8)!
        return publicKey.isValidSignature(signature, for: messageData)
    }
    
}
