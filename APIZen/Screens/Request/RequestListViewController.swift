//
//  RequestListViewController.swift
//  APIZen
//
//  Created by Jaseem V V on 09/12/19.
//  Copyright © 2019 Jaseem V V. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import AZCommon
import AZData

extension Notification.Name {
    static let navigatedBackToRequestList = Notification.Name("navigated-back-to-request-list")
    static let requestListVCShouldPresent = Notification.Name("request-list-vc-should-present")
}

class RequestListViewController: APITesterProViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var filterBtn: UIBarButtonItem!
    @IBOutlet weak var windowBtn: UIBarButtonItem!
    @IBOutlet weak var addBtn: UIBarButtonItem!
    @IBOutlet weak var helpTextLabel: UILabel!
    private let utils = AZUtils.shared
    private let app: App = App.shared
    private lazy var localdb = { CoreDataService.shared }()
    private lazy var localdbSvc = { PersistenceService.shared }()
    private var frc: NSFetchedResultsController<ERequest>!
    private let cellReuseId = "requestCell"
    // private lazy var db = { PersistenceService.shared }()
    private let nc = NotificationCenter.default
    var project: EProject?
    var methods: [ERequestMethodData] = []
    var isCopyOrMoveMode = false
    var isMove = false
    
    deinit {
        self.nc.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.frc != nil { self.frc.delegate = nil }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isNavigatedBack { self.nc.post(name: .navigatedBackToRequestList, object: self) }
        AppState.setCurrentScreen(.requestList)
        self.navigationItem.title = "Requests"
        if self.frc != nil { self.frc.delegate = self }
        self.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        self.initData()
        self.initEvents()
    }
    
    override func initUI() {
        super.initUI()
        self.app.updateViewBackground(self.view)
        self.app.updateNavigationControllerBackground(self.navigationController)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addBtnDidTap(_:)))
        self.tableView.register(ActionButtonsCell.self, forCellReuseIdentifier: "ActionButtonsCell")

    }
    
    func initEvents() {
        self.nc.addObserver(self, selector: #selector(self.databaseWillUpdate(_:)), name: .databaseWillUpdate, object: nil)
        self.nc.addObserver(self, selector: #selector(self.databaseDidUpdate(_:)), name: .databaseDidUpdate, object: nil)
        self.nc.addObserver(self, selector: #selector(self.requestDidChange(_:)), name: .requestDidChange, object: nil)
    }
    
    func getFRCPredicate(_ projId: String) -> NSPredicate {
        return NSPredicate(format: "project.id == %@ AND name != %@ AND markForDelete == %hdd", projId, "", false)
    }
    
    func initData() {
        if self.frc == nil, let projId = self.project?.getId(), let ctx = self.project?.managedObjectContext {
            let predicate = self.getFRCPredicate(projId)
            if let _frc = self.localdb.getFetchResultsController(obj: ERequest.self, predicate: predicate, ctx: ctx) as? NSFetchedResultsController<ERequest> {
                self.frc = _frc
                self.frc.delegate = self
            }
            self.methods = self.localdb.getRequestMethodData(projId: projId, ctx: ctx)
        }
        self.reloadData()
    }
    
    func updateData() {
        guard let projId = self.project?.getId(), let ctx = self.project?.managedObjectContext else { return }
        self.methods = self.localdb.getRequestMethodData(projId: projId, ctx: ctx)
        if self.frc == nil { return }
        self.frc.delegate = nil
        try? self.frc.performFetch()
        self.frc.delegate = self
        self.checkHelpShouldDisplay()
        self.tableView.reloadData()
    }
    
    @objc func requestDidChange(_ notif: Notification) {
        Log.debug("request did change - refreshing list")
        self.updateData()
    }
    
    @objc func databaseWillUpdate(_ notif: Notification) {
        DispatchQueue.main.async { self.frc.delegate = nil }
    }
    
    @objc func databaseDidUpdate(_ notif: Notification) {
        DispatchQueue.main.async {
            self.frc.delegate = self
            self.reloadData()
        }
    }
    
    func checkHelpShouldDisplay() {
        if self.frc.numberOfRows(in: 0) == 0 {
            self.displayHelpText()
        } else {
            self.hideHelpText()
        }
    }
    
    func reloadData() {
        if self.frc == nil { return }
        do {
            try self.frc.performFetch()
            self.checkHelpShouldDisplay()
            self.tableView.reloadData()
        } catch let error {
            Log.error("Error fetching: \(error)")
        }
    }
    
    func displayHelpText() {
        UIView.animate(withDuration: 0.3) {
            self.helpTextLabel.isHidden = false
        }
    }
    
    func hideHelpText() {
        UIView.animate(withDuration: 0.3) {
            self.helpTextLabel.isHidden = true
        }
    }
    
    @objc func addBtnDidTap(_ sender: Any) {
        Log.debug("add btn did tap")
        if let vc = UIStoryboard.editRequestVC, let projId = self.project?.getId(), let ws = self.project?.workspace {
            vc.bootstrap(ws: ws, projectId: projId)
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }
}

class RequestCell: UITableViewCell {
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var descLbl: UILabel!
    @IBOutlet weak var bottomBorder: UIView!
    
    func hideBottomBorder() {
        self.bottomBorder.isHidden = true
    }
    
    func displayBottomBorder() {
        self.bottomBorder.isHidden = false
    }
}

extension RequestListViewController: UITableViewDelegate, UITableViewDataSource {
    func getDesc(req: ERequest) -> String {
        let method = req.method?.name ?? ""
        let url = req.url ?? ""
        var path = ""
        if !url.isEmpty {
            if url.firstIndex(of: "{") != nil {
                if let idx = url.firstIndex(of: "/") {
                    path = String(url.suffix(from: idx))
                }
            } else {
                path = URL(string: url)?.path ?? url
            }
        }
        return "\(method) \(path.isEmpty ? "/" : path)"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.isCopyOrMoveMode {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isCopyOrMoveMode && section == 0 {
            return 1
        }
        return self.frc.numberOfRows(in: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.isCopyOrMoveMode && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionButtonsCell", for: indexPath) as! ActionButtonsCell
            cell.cancelButton.addTarget(self, action: #selector(cancelButtonDidTap), for: .touchUpInside)
            cell.pasteButton.addTarget(self, action: #selector(pasteButtonDidTap), for: .touchUpInside)
            cell.selectionStyle = .none
            return cell
        }
        let idxPath = IndexPath(row: indexPath.row, section: 0)
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath) as! RequestCell
        let req = self.frc.object(at: idxPath)
        cell.nameLbl.text = req.name
        let desc = self.getDesc(req: req)
        cell.descLbl.text = desc
        if desc.isEmpty {
            cell.descLbl.isHidden = true
        } else {
            cell.descLbl.isHidden = false
        }
        cell.displayBottomBorder()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let req = self.frc.object(at: indexPath)
        if let vc = UIStoryboard.requestTabBar, let ctx = req.managedObjectContext {
            vc.updateRequest(reqId: req.getId(), ctx: ctx)
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
            Log.debug("delete row: \(indexPath)")
            let req = self.frc.object(at: indexPath)
            self.localdbSvc.deleteEntity(req: req)
            self.localdb.saveMainContext()
            self.updateData()
            completion(true)
        }
        delete.image = UIImage(systemName: "xmark.bin")
        let copy = UIContextualAction(style: .normal, title: "Copy") { (action, view, completionHandler) in
            Log.debug("Copy tapped for row \(indexPath.row)")
            let req = self.frc.object(at: indexPath)
            AppState.setCopyRequest(req)
            self.isCopyOrMoveMode = true
            self.tableView.reloadData()
            completionHandler(true)
        }
        copy.image = UIImage(systemName: "doc.on.doc")
        copy.backgroundColor = .systemBlue
        let move = UIContextualAction(style: .normal, title: "Move") { (action, view, completionHandler) in
            Log.debug("Move tapped for row \(indexPath.row)")
            let req = self.frc.object(at: indexPath)
            AppState.setMoveRequest(req)
            self.isCopyOrMoveMode = true
            self.tableView.reloadData()
            completionHandler(true)
        }
        move.image = UIImage(systemName: "folder")
        move.backgroundColor = .systemOrange
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete, copy, move])
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let idxPath = IndexPath(row: indexPath.row, section: 0)
        let req = self.frc.object(at: idxPath)
        let name = req.name ?? ""
        let desc = self.getDesc(req: req)
        let w = tableView.frame.width
        let h1 = name.height(width: w, font: App.Font.font17) + 20
        let h2: CGFloat =  desc.isEmpty ? 0 : desc.height(width: w, font: App.Font.font15) + 10
        return max(h1 + h2, 46)
    }
    
    @objc func cancelButtonDidTap() {
        Log.debug("cancel button did tap")
        self.isCopyOrMoveMode = false
        self.tableView.reloadData()
    }
    
    @objc func pasteButtonDidTap() {
        Log.debug("paste button did tap")
        self.isCopyOrMoveMode = false
        self.tableView.reloadData()
        var reqToCopyOrMove: ERequest?
        if isMove {
            reqToCopyOrMove = AppState.getMoveRequest()
        } else {
            reqToCopyOrMove = AppState.getCopyRequest()
        }
        guard let req = reqToCopyOrMove else { return }
        if !isMove {
            if let currProj = AppState.currentProject, let ctx = currProj.managedObjectContext {
                let newReq = req.copyEntity(currProj, ctx: ctx)
                self.localdb.saveMainContext()
                self.updateData()
            }
        }
    }
}

extension RequestListViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        Log.debug("requests list frc did change: \(anObject)")
        if AppState.currentScreen != .requestList { return }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            switch type {
            case .insert:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.tableView.scrollToBottom(section: 0) }
            default:
                break
            }
        }
    }
}

class ActionButtonsCell: UITableViewCell {
    let cancelButton = UIButton(type: .system)
    let pasteButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.cancelButton.setTitle("Cancel", for: .normal)
        self.pasteButton.setTitle("Paste", for: .normal)
        
        [self.cancelButton, self.pasteButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            self.cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            self.cancelButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            self.pasteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            self.pasteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

