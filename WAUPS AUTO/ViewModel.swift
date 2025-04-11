//
//  ViewModel.swift
//  WAUPS AUTO
//
//  Created by 唐梓皓 on 2025/4/6.
//

import Foundation
import SwiftUI

class ViewModel: ObservableObject {
    
    @Published var tipsText: String = "未在执行"
    @Published var tipsTextColor: Color = .primary
    
    @Published var auth: Bool = false
    
    @Published private(set) var timeRemaining = 120
    @Published private(set) var timer: Timer?
    
    
    // 1. 关机命令
    func shutdownMacAsync() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/sudo"
        process.arguments = ["/sbin/shutdown", "-h", "+2"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        
        // 设置异步读取管道输出
        fileHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("Shutdown output: \(output)")
            }
        }
        
        // 进程退出时的处理
        process.terminationHandler = { [self] proc in
            if proc.terminationStatus != 0 {
                tipsText = "未授权APP执行关机命令"
                tipsTextColor = .red
                timer?.invalidate()
                timer = nil
            }
            print("Process terminated with status: \(proc.terminationStatus)")
            fileHandle.readabilityHandler = nil  // 清理
        }
        
        do {
            try process.run()
            tipsText = "已执行关机命令"
            tipsTextColor = .green
            print("Shutdown command issued.")
            return true
        } catch {
            tipsText = "关机指令无法执行"
            tipsTextColor = .red
            print("Error running shutdown: \(error)")
            return false
        }
    }
    
    // 2. 删除授权文件命令
    func revokeShutdownPermission() {
        let process = Process()
        process.launchPath = "/usr/bin/sudo"
        process.arguments = ["/bin/rm", "/etc/sudoers.d/shutdown_nopasswd"]
        
        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("Revoke permission output: \(output)")
                if output.isEmpty {
                    tipsText = "已撤销命令授权"
                    tipsTextColor = .green
                } else if output.contains("sudo: a password is required") {
                    tipsText = "无需撤销授权"
                    tipsTextColor = .primary
                }
            }
        } catch {
            tipsText = "撤销授权失败"
            tipsTextColor = .red
            print("Error: \(error)")
        }
    }
    
    // 3. 终止关机进程命令
    func killShutdownProcess() {
        let process = Process()
        process.launchPath = "/usr/bin/sudo"
        process.arguments = ["/usr/bin/killall", "shutdown"]
        
        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if output.isEmpty {
                    timer?.invalidate()
                    timer = nil
                    tipsText = "已撤销关机命令"
                    tipsTextColor = .green
                } else if output.contains("No matching processes were found") {
                    tipsText = "目前无关机命令"
                    tipsTextColor = .primary
                }
                print("Kill shutdown process output: \(output)")
            }
        } catch {
            tipsText = "已撤销关机命令"
            tipsTextColor = .green
            print("Error: \(error)")
        }
    }
    
    func checkSudoersFile() -> Bool {
        let fileManager = FileManager.default
        let filePath = "/etc/sudoers.d/shutdown_nopasswd"
        
        // 1. 检查文件是否存在
        if fileManager.fileExists(atPath: filePath) {
            print("文件存在")
            tipsText = "已授权APP执行关机命令"
            tipsTextColor = .green
            return true
        } else {
            print("文件不存在")
            tipsText = "未授权APP执行关机命令"
            tipsTextColor = .red
            return false
        }
    }
    
    func startCountdown() {
        timer?.invalidate() // 防止重复定时器
        timeRemaining = 120
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            if timeRemaining > 0 {
                tipsText = "关机倒计时：\(timeRemaining)秒"
                tipsTextColor = .red
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}
