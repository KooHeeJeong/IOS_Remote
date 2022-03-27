//
//  ViewController.swift
//  Notice
//
//  Created by 구희정 on 2022/03/25.
//

import UIKit
import FirebaseRemoteConfig
import FirebaseAnalytics

class ViewController: UIViewController {

    var remoteConfig : RemoteConfig?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.remoteConfig = RemoteConfig.remoteConfig()
        
        //최대한 자주 원격 구성에 있는 값을 가져오도록 한다.
        let setting = RemoteConfigSettings()
        setting.minimumFetchInterval = 0
        
        remoteConfig?.configSettings = setting
        remoteConfig?.setDefaults(fromPlist: "RemoteConfigDefaultPropertyList")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getNotice()
    }
    
}

//RemoteConfig
extension ViewController {
    func getNotice() {
        guard let remoteConfig = remoteConfig else  { return }
        
        //status - 상태
        //_ 에러
        remoteConfig.fetch {[weak self] status, _ in
            if status == .success {
                remoteConfig.activate(completion: nil)
            } else {
                print("Error : Config not feched")
            }
            
            guard let self = self else { return }
            
            if !self.isNoticeHidden(remoteConfig) {
                let noticeVC = NoticeViewController(nibName: "NoticeViewController", bundle: nil)
                
                noticeVC.modalTransitionStyle = .crossDissolve
                noticeVC.modalPresentationStyle = .custom
                
                //Swift의 줄바꿈 = \n
                //줄바꿈 문법을 FireBase에 저장을 \n 으로
                //호출해서 데이터를 가져올 때 \\n 으로 된다.
                //그래서 replacingOccurrences 값으로 값을 바꿔준다.
                let title = (remoteConfig["title"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let detail = (remoteConfig["detail"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let date = (remoteConfig["date"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                
                //미리 만들어둔 noticeContents 딕셔너리에 값을 넣어준다.
                noticeVC.noticeContents = (title : title, detail : detail, date : date)
                self.present(noticeVC, animated: true, completion: nil)
            } else {
                self.showEventAlert()
            }
        }
    }
    
    //remoteConfig의 'isHidden'으로 되어있는 키 값을 가져온다.
    //isHidden 이 true 면 팝업 숨김
    //isHidden 이 false 면 팝업 보여줌
    func isNoticeHidden(_ remoteConfig : RemoteConfig) -> Bool {
        return remoteConfig["isHidden"].boolValue
    }
}

//A/B TEST
extension ViewController {
    func showEventAlert() {
        guard let remoteConfig = remoteConfig else { return }
        
        remoteConfig.fetch {[weak self] status, _  in
            if status == .success {
                remoteConfig.activate(completion: nil)
            } else {
                print("Error : Config not fetched")
            }
            
            let message = remoteConfig["message"].stringValue ?? ""
            
            let confirmAction = UIAlertAction(title: "확인하기", style: .default) {_ in 
                //Google Analytics
                Analytics.logEvent("promotion_alert", parameters: nil)
            }
            
            let cancelAction = UIAlertAction(title: "취소", style: .cancel)
            let alertController = UIAlertController(title: "깜짝이벤트", message: message, preferredStyle: .alert)
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
}
