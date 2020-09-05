//
//  ViewController.swift
//  taskapp
//
//  Created by 杉山貴哉 on 2020/09/03.
//  Copyright © 2020 TakayaSugiyama. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    //Realmインスタンスを取得する
    let realm = try! Realm()
    
    //DB内のタスクが格納されるリスト
    //DBに近い順でソート
    //以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    // セルの数を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString: String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
    }

    //各セルを選択された時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除が可能なことがを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

   // Delete ボタンが押された時に呼ばれるメソッド
   func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
       // --- ここから ---
       if editingStyle == .delete {
            let task = self.taskArray[indexPath.row]
           // ローカル通知をキャンセルする
           let center = UNUserNotificationCenter.current()
           center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
          // データベースから削除する
           try! realm.write {
               self.realm.delete(self.taskArray[indexPath.row])
               tableView.deleteRows(at: [indexPath], with: .fade)
           }
          // 未通知のローカル通知一覧をログ出力
         center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
             for request in requests {
                 print("/---------------")
                 print(request)
                 print("---------------/")
             }
         }
       }
   }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        }else{
            let task = Task()
            
            let allTask = realm.objects(Task.self)
            if allTask.count != 0 {
                task.id = allTask.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
        }
    }
    
    //入力画面から戻ってきた時に、TableViewを更新される
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

