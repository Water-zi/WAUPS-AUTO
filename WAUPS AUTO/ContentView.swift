//
//  ContentView.swift
//  WAUPS AUTO
//
//  Created by 唐梓皓 on 2025/4/5.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            
            Text("WAUPS MINI 自动关机辅助程序")
                .font(.largeTitle.bold())
            
            Text("请慎防黑客利用命令攻击你的电脑")
                .font(.headline)
                .foregroundStyle(.red)
            
            Divider()
            
            Text("--- 可控的风险 ---\n你授权了\"sudo shutdown -h +2\"无密码运行，该命令的含义为2分钟后关机\n如果有软件恶意执行该命令，你可以在缓冲时间内点击下方按钮")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
            
            HStack {
                Button {
                    viewModel.killShutdownProcess()
                    viewModel.revokeShutdownPermission()
                } label: {
                    Text("取消关机并撤销授权")
                        .font(.system(size: 20))
                        .padding(10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .cornerRadius(12)
                
                Button {
                    viewModel.killShutdownProcess()
                } label: {
                    Text("仅取消关机")
                        .font(.system(size: 20))
                        .padding(10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .cornerRadius(12)
            }
            
            Divider()
            
            ZStack {
                Text("--- 授权APP自动关机 ---")
                    .font(.headline)
                
                HStack {
                    Spacer()
                    Button {
                        viewModel.auth = viewModel.checkSudoersFile()
                    } label: {
                        Text("检查")
                    }
                    
                    Image(systemName: viewModel.auth ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.auth ? .green : .red)
                    
                }
                
            }
            
            VStack(spacing: 10) {
                HStack {
                    Text("在\"终端\"中输入命令并回车，将APP所需命令设置为无需密码执行")
                    Spacer()
                    Button {
                        let command = """
                        echo "$(whoami) ALL=(ALL) NOPASSWD: /sbin/shutdown -h +2, /bin/rm /etc/sudoers.d/shutdown_nopasswd, /usr/bin/killall shutdown" | sudo tee /etc/sudoers.d/shutdown_nopasswd && sudo chmod 440 /etc/sudoers.d/shutdown_nopasswd
                        """
                        
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(command, forType: .string)
                        
                        print("Command copied to clipboard!")
                        if let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
                            NSWorkspace.shared.openApplication(at: terminalURL,
                                                               configuration: NSWorkspace.OpenConfiguration(),
                                                               completionHandler: nil)
                        }
                    } label: {
                        Text("复制命令并打开终端")
                    }
                }
                HStack {
                    Text("提示：执行命令时，会要求输入密码，所输入的密码不会显示，输入完成后直接按回车即可")
                    Spacer()
                }
                HStack {
                    Text("所涉及的命令为包括：\n\"sudo /sbin/shutdown -h +2\"\n\"sudo /bin/rm /etc/sudoers.d/shutdown_nopasswd\"\n\"sudo killall shutdown\"")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\n两分钟后关机\n撤销允许无密码运行的授权\n取消自动关机")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Divider()
            
            ZStack {
                Text("--- 自动关机任务 ---")
                    .font(.headline)
                
                HStack {
                    Spacer()
                    Button {
                        if viewModel.shutdownMacAsync() {
                            viewModel.startCountdown()
                        }
                    } label: {
                        Text("测试")
                    }
                    
                }
            }
            
            Text(viewModel.tipsText)
                .foregroundStyle(viewModel.tipsTextColor)
                .font(.largeTitle)
                .bold()
            
        }
        .padding()
        .onAppear {
            viewModel.auth = viewModel.checkSudoersFile()
        }
        .frame(minWidth: 650, minHeight: 480)
    }
    
}

#Preview {
    ContentView()
}
