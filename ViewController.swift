// ViewController.swift
import UIKit

struct Upgrade {
    let name: String
    let icon: String
    var baseCost: Int
    var bpsIncrease: Double
    var owned: Int = 0
    
    var currentCost: Int {
        return Int(Double(baseCost) * pow(1.15, Double(owned)))
    }
}

struct ClickUpgrade {
    let name: String
    let icon: String
    var baseCost: Int
    var clickBonus: Int
    var owned: Int = 0
    
    var currentCost: Int {
        return Int(Double(baseCost) * pow(1.2, Double(owned)))
    }
}

class ViewController: UIViewController {
    
    var clickCount: Int = 0 {
        didSet { 
            UserDefaults.standard.set(clickCount, forKey: "clickCount")
            updateLabels()
            upgradesTableView.reloadData()
            clickUpgradesTableView.reloadData()
            updateRebirthButton()
        }
    }
    var totalClicks: Int = 0 {
        didSet { UserDefaults.standard.set(totalClicks, forKey: "totalClicks") }
    }
    var rebirthCount: Int = 0 {
        didSet { 
            UserDefaults.standard.set(rebirthCount, forKey: "rebirthCount")
            updateLabels()
        }
    }
    var clickPower: Int {
        let baseClick = 1 + rebirthCount * 2
        let upgradeBonus = clickUpgrades.reduce(0) { $0 + ($1.clickBonus * $1.owned) }
        return baseClick + upgradeBonus
    }
    var boogermanPerSecond: Double = 0
    var clickTimes: [Date] = []
    var cpsTimer: Timer?
    var passiveIncomeTimer: Timer?
    var currentTab: Tab = .bpsUpgrades
    
    enum Tab {
        case bpsUpgrades
        case clickUpgrades
    }
    
    var upgrades: [Upgrade] = [
        Upgrade(name: "Cursor", icon: "👆", baseCost: 15, bpsIncrease: 0.1),
        Upgrade(name: "Booger Jar", icon: "🫙", baseCost: 100, bpsIncrease: 1),
        Upgrade(name: "Tissue Box", icon: "🧻", baseCost: 1100, bpsIncrease: 8),
        Upgrade(name: "Nose Picker", icon: "👃", baseCost: 12000, bpsIncrease: 47),
        Upgrade(name: "Sneeze Factory", icon: "🤧", baseCost: 130000, bpsIncrease: 260),
        Upgrade(name: "Mucus Mine", icon: "⛏️", baseCost: 1400000, bpsIncrease: 1400)
    ]
    
    var clickUpgrades: [ClickUpgrade] = [
        ClickUpgrade(name: "Better Finger", icon: "☝️", baseCost: 100, clickBonus: 1),
        ClickUpgrade(name: "Power Glove", icon: "🧤", baseCost: 500, clickBonus: 5),
        ClickUpgrade(name: "Mega Clicker", icon: "💪", baseCost: 2500, clickBonus: 25),
        ClickUpgrade(name: "Auto Clicker", icon: "🤖", baseCost: 10000, clickBonus: 100),
        ClickUpgrade(name: "Quantum Tap", icon: "⚡", baseCost: 50000, clickBonus: 500)
    ]
    
    let rebirthRequirement = 100000
    
    let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textAlignment = .center
        label.textColor = .white
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 2, height: 2)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let rebirthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.textColor = .orange
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let clickPowerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .green
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let bpsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .cyan
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let cpsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .yellow
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let tabSegmentedControl: UISegmentedControl = {
        let items = ["BPS Upgrades", "Click Upgrades"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    let upgradesTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        tv.separatorColor = UIColor.white.withAlphaComponent(0.2)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    let clickUpgradesTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        tv.separatorColor = UIColor.white.withAlphaComponent(0.2)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isHidden = true
        return tv
    }()
    
    let rebirthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🌟 REBIRTH", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.8)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🔄", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadGameData()
        setupBackground()
        setupImage()
        setupTableView()
        setupLayout()
        setupGestures()
        updateLabels()
        startTimers()
        updateRebirthButton()
    }
    
    func loadGameData() {
        clickCount = UserDefaults.standard.integer(forKey: "clickCount")
        totalClicks = UserDefaults.standard.integer(forKey: "totalClicks")
        rebirthCount = UserDefaults.standard.integer(forKey: "rebirthCount")
        
        if let upgradesData = UserDefaults.standard.data(forKey: "upgrades"),
           let decoded = try? JSONDecoder().decode([UpgradeData].self, from: upgradesData) {
            for (index, data) in decoded.enumerated() {
                if index < upgrades.count {
                    upgrades[index].owned = data.owned
                }
            }
        }
        
        if let clickUpgradesData = UserDefaults.standard.data(forKey: "clickUpgrades"),
           let decoded = try? JSONDecoder().decode([UpgradeData].self, from: clickUpgradesData) {
            for (index, data) in decoded.enumerated() {
                if index < clickUpgrades.count {
                    clickUpgrades[index].owned = data.owned
                }
            }
        }
        
        calculateBPS()
    }
    
    func saveGameData() {
        let upgradesData = upgrades.map { UpgradeData(owned: $0.owned) }
        if let encoded = try? JSONEncoder().encode(upgradesData) {
            UserDefaults.standard.set(encoded, forKey: "upgrades")
        }
        
        let clickUpgradesData = clickUpgrades.map { UpgradeData(owned: $0.owned) }
        if let encoded = try? JSONEncoder().encode(clickUpgradesData) {
            UserDefaults.standard.set(encoded, forKey: "clickUpgrades")
        }
    }
    
    func calculateBPS() {
        boogermanPerSecond = upgrades.reduce(0) { $0 + ($1.bpsIncrease * Double($1.owned)) }
    }
    
    func setupBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1).cgColor,
            UIColor(red: 0.0, green: 0.4, blue: 0.5, alpha: 1).cgColor
        ]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setupImage() {
        if let image = UIImage(named: "hero") {
            heroImageView.image = image
        } else {
            heroImageView.backgroundColor = UIColor.orange.withAlphaComponent(0.3)
            heroImageView.layer.cornerRadius = 20
            heroImageView.layer.borderWidth = 3
            heroImageView.layer.borderColor = UIColor.yellow.cgColor
            
            let label = UILabel()
            label.text = "B"
            label.font = UIFont.boldSystemFont(ofSize: 80)
            label.textColor = .yellow
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            heroImageView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: heroImageView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: heroImageView.centerYAnchor)
            ])
        }
    }
    
    func setupTableView() {
        upgradesTableView.delegate = self
        upgradesTableView.dataSource = self
        upgradesTableView.register(UpgradeCell.self, forCellReuseIdentifier: "UpgradeCell")
        
        clickUpgradesTableView.delegate = self
        clickUpgradesTableView.dataSource = self
        clickUpgradesTableView.register(ClickUpgradeCell.self, forCellReuseIdentifier: "ClickUpgradeCell")
    }
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(heroTapped))
        heroImageView.addGestureRecognizer(tapGesture)
        resetButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        rebirthButton.addTarget(self, action: #selector(performRebirth), for: .touchUpInside)
        tabSegmentedControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
    }
    
    func setupLayout() {
        view.addSubview(scoreLabel)
        view.addSubview(rebirthLabel)
        view.addSubview(clickPowerLabel)
        view.addSubview(bpsLabel)
        view.addSubview(cpsLabel)
        view.addSubview(heroImageView)
        view.addSubview(rebirthButton)
        view.addSubview(tabSegmentedControl)
        view.addSubview(upgradesTableView)
        view.addSubview(clickUpgradesTableView)
        view.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            rebirthLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 3),
            rebirthLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            clickPowerLabel.topAnchor.constraint(equalTo: rebirthLabel.bottomAnchor, constant: 3),
            clickPowerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            bpsLabel.topAnchor.constraint(equalTo: clickPowerLabel.bottomAnchor, constant: 3),
            bpsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cpsLabel.topAnchor.constraint(equalTo: bpsLabel.bottomAnchor, constant: 3),
            cpsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            heroImageView.topAnchor.constraint(equalTo: cpsLabel.bottomAnchor, constant: 10),
            heroImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heroImageView.widthAnchor.constraint(equalToConstant: 150),
            heroImageView.heightAnchor.constraint(equalToConstant: 150),
            
            rebirthButton.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 10),
            rebirthButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rebirthButton.widthAnchor.constraint(equalToConstant: 200),
            rebirthButton.heightAnchor.constraint(equalToConstant: 40),
            
            tabSegmentedControl.topAnchor.constraint(equalTo: rebirthButton.bottomAnchor, constant: 10),
            tabSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tabSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            upgradesTableView.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor, constant: 10),
            upgradesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            upgradesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            upgradesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            clickUpgradesTableView.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor, constant: 10),
            clickUpgradesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            clickUpgradesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            clickUpgradesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            resetButton.widthAnchor.constraint(equalToConstant: 50),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func tabChanged() {
        currentTab = tabSegmentedControl.selectedSegmentIndex == 0 ? .bpsUpgrades : .clickUpgrades
        upgradesTableView.isHidden = currentTab == .clickUpgrades
        clickUpgradesTableView.isHidden = currentTab == .bpsUpgrades
    }
    
    @objc func heroTapped() {
        clickCount += clickPower
        totalClicks += 1
        clickTimes.append(Date())
        
        animateTap()
        createParticle()
        addHapticFeedback()
    }
    
    func updateLabels() {
        scoreLabel.text = "Boogerman: \(clickCount.formatted())"
        rebirthLabel.text = "⭐ Rebirths: \(rebirthCount)"
        clickPowerLabel.text = "👆 Click Power: +\(clickPower)"
        bpsLabel.text = String(format: "Boogerman per second: %.1f", boogermanPerSecond)
    }
    
    func updateRebirthButton() {
        let canRebirth = clickCount >= rebirthRequirement
        rebirthButton.isEnabled = canRebirth
        rebirthButton.alpha = canRebirth ? 1.0 : 0.5
        
        if canRebirth {
            rebirthButton.setTitle("🌟 REBIRTH (Ready!)", for: .normal)
        } else {
            let remaining = rebirthRequirement - clickCount
            rebirthButton.setTitle("🌟 REBIRTH (\(remaining.formatted()) needed)", for: .normal)
        }
    }
    
    @objc func performRebirth() {
        guard clickCount >= rebirthRequirement else { return }
        
        let alert = UIAlertController(
            title: "🌟 REBIRTH? 🌟",
            message: "Reset all progress but gain +2 click power permanently!\n\nCurrent click power: \(clickPower)\nAfter rebirth: \(clickPower + 2)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "REBIRTH!", style: .default) { [weak self] _ in
            self?.executeRebirth()
        })
        
        present(alert, animated: true)
    }
    
    func executeRebirth() {
        rebirthCount += 1
        clickCount = 0
        totalClicks = 0
        clickTimes.removeAll()
        
        for i in 0..<upgrades.count {
            upgrades[i].owned = 0
        }
        
        calculateBPS()
        saveGameData()
        updateLabels()
        upgradesTableView.reloadData()
        clickUpgradesTableView.reloadData()
        updateRebirthButton()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showRebirthAnimation()
    }
    
    func showRebirthAnimation() {
        let starLabel = UILabel()
        starLabel.text = "🌟"
        starLabel.font = UIFont.systemFont(ofSize: 100)
        starLabel.alpha = 0
        starLabel.center = heroImageView.center
        view.addSubview(starLabel)
        
        UIView.animate(withDuration: 0.5, animations: {
            starLabel.alpha = 1
            starLabel.transform = CGAffineTransform(scaleX: 2, y: 2)
        }) { _ in
            UIView.animate(withDuration: 0.5, animations: {
                starLabel.alpha = 0
                starLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }) { _ in
                starLabel.removeFromSuperview()
            }
        }
    }
    
    func animateTap() {
        UIView.animate(withDuration: 0.08, animations: {
            self.heroImageView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.08) {
                self.heroImageView.transform = .identity
            }
        }
    }
    
    func createParticle() {
        let particle = UILabel()
        particle.text = ["+\(clickPower)", "💚", "🤢", "✨"].randomElement()!
        particle.font = UIFont.boldSystemFont(ofSize: 24)
        particle.textColor = .green
        particle.shadowColor = .black
        particle.shadowOffset = CGSize(width: 1, height: 1)
        
        let randomX = heroImageView.center.x + CGFloat.random(in: -40...40)
        particle.center = CGPoint(x: randomX, y: heroImageView.center.y)
        view.addSubview(particle)
        
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseOut, animations: {
            particle.center.y -= 80
            particle.alpha = 0
            particle.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            particle.removeFromSuperview()
        }
    }
    
    func addHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func startTimers() {
        cpsTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCPS()
        }
        
        passiveIncomeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.addPassiveIncome()
        }
    }
    
    func updateCPS() {
        let now = Date()
        clickTimes = clickTimes.filter { now.timeIntervalSince($0) <= 1.0 }
        let cps = Double(clickTimes.count)
        cpsLabel.text = String(format: "Click Power: +%.0f", cps)
    }
    
    func addPassiveIncome() {
        if boogermanPerSecond > 0 {
            clickCount += Int(boogermanPerSecond * 0.1)
        }
    }
    
    @objc func resetGame() {
        let alert = UIAlertController(
            title: "Reset Game?",
            message: "This will reset EVERYTHING including rebirths!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.performReset()
        })
        
        present(alert, animated: true)
    }
    
    func performReset() {
        clickCount = 0
        totalClicks = 0
        rebirthCount = 0
        clickTimes.removeAll()
        
        for i in 0..<upgrades.count {
            upgrades[i].owned = 0
        }
        
        for i in 0..<clickUpgrades.count {
            clickUpgrades[i].owned = 0
        }
        
        calculateBPS()
        saveGameData()
        updateLabels()
        upgradesTableView.reloadData()
        clickUpgradesTableView.reloadData()
        updateRebirthButton()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    deinit {
        cpsTimer?.invalidate()
        passiveIncomeTimer?.invalidate()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == upgradesTableView {
            return upgrades.count
        } else {
            return clickUpgrades.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == upgradesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpgradeCell", for: indexPath) as! UpgradeCell
            let upgrade = upgrades[indexPath.row]
            let canAfford = clickCount >= upgrade.currentCost
            cell.configure(with: upgrade, canAfford: canAfford)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ClickUpgradeCell", for: indexPath) as! ClickUpgradeCell
            let upgrade = clickUpgrades[indexPath.row]
            let canAfford = clickCount >= upgrade.currentCost
            cell.configure(with: upgrade, canAfford: canAfford)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView == upgradesTableView {
            let upgrade = upgrades[indexPath.row]
            
            if clickCount >= upgrade.currentCost {
                clickCount -= upgrade.currentCost
                upgrades[indexPath.row].owned += 1
                calculateBPS()
                saveGameData()
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                tableView.reloadRows(at: [indexPath], with: .fade)
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        } else {
            let upgrade = clickUpgrades[indexPath.row]
            
            if clickCount >= upgrade.currentCost {
                clickCount -= upgrade.currentCost
                clickUpgrades[indexPath.row].owned += 1
                saveGameData()
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                tableView.reloadRows(at: [indexPath], with: .fade)
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

class UpgradeCell: UITableViewCell {
    
    let iconLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let bpsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .cyan
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let costLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .yellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let ownedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        contentView.addSubview(iconLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bpsLabel)
        contentView.addSubview(costLabel)
        contentView.addSubview(ownedLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            
            bpsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bpsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
            costLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            costLabel.topAnchor.constraint(equalTo: bpsLabel.bottomAnchor, constant: 2),
            
            ownedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            ownedLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ownedLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with upgrade: Upgrade, canAfford: Bool) {
        iconLabel.text = upgrade.icon
        nameLabel.text = upgrade.name
        bpsLabel.text = String(format: "+%.1f BPS", upgrade.bpsIncrease)
        costLabel.text = "💰 \(upgrade.currentCost.formatted())"
        ownedLabel.text = "\(upgrade.owned)"
        
        contentView.alpha = canAfford ? 1.0 : 0.5
    }
}

class ClickUpgradeCell: UITableViewCell {
    
    let iconLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let clickBonusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .green
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let costLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .yellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let ownedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        contentView.addSubview(iconLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(clickBonusLabel)
        contentView.addSubview(costLabel)
        contentView.addSubview(ownedLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            
            clickBonusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            clickBonusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
            costLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            costLabel.topAnchor.constraint(equalTo: clickBonusLabel.bottomAnchor, constant: 2),
            
            ownedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            ownedLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ownedLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with upgrade: ClickUpgrade, canAfford: Bool) {
        iconLabel.text = upgrade.icon
        nameLabel.text = upgrade.name
        clickBonusLabel.text = "+\(upgrade.clickBonus) per click"
        costLabel.text = "💰 \(upgrade.currentCost.formatted())"
        ownedLabel.text = "\(upgrade.owned)"
        
        contentView.alpha = canAfford ? 1.0 : 0.5
    }
}

struct UpgradeData: Codable {
    let owned: Int
}

extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
