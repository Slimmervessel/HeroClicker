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

class ViewController: UIViewController {
    
    var clickCount: Int = 0 {
        didSet { 
            UserDefaults.standard.set(clickCount, forKey: "clickCount")
            updateLabels()
            upgradesTableView.reloadData()
        }
    }
    var totalClicks: Int = 0 {
        didSet { UserDefaults.standard.set(totalClicks, forKey: "totalClicks") }
    }
    var boogermanPerSecond: Double = 0
    var clickTimes: [Date] = []
    var cpsTimer: Timer?
    var passiveIncomeTimer: Timer?
    
    var upgrades: [Upgrade] = [
        Upgrade(name: "Cursor", icon: "👆", baseCost: 15, bpsIncrease: 0.1),
        Upgrade(name: "Booger Jar", icon: "🫙", baseCost: 100, bpsIncrease: 1),
        Upgrade(name: "Tissue Box", icon: "🧻", baseCost: 1100, bpsIncrease: 8),
        Upgrade(name: "Nose Picker", icon: "👃", baseCost: 12000, bpsIncrease: 47),
        Upgrade(name: "Sneeze Factory", icon: "🤧", baseCost: 130000, bpsIncrease: 260),
        Upgrade(name: "Mucus Mine", icon: "⛏️", baseCost: 1400000, bpsIncrease: 1400)
    ]
    
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
    
    let upgradesTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        tv.separatorColor = UIColor.white.withAlphaComponent(0.2)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
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
    }
    
    func loadGameData() {
        clickCount = UserDefaults.standard.integer(forKey: "clickCount")
        totalClicks = UserDefaults.standard.integer(forKey: "totalClicks")
        
        if let upgradesData = UserDefaults.standard.data(forKey: "upgrades"),
           let decoded = try? JSONDecoder().decode([UpgradeData].self, from: upgradesData) {
            for (index, data) in decoded.enumerated() {
                if index < upgrades.count {
                    upgrades[index].owned = data.owned
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
    }
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(heroTapped))
        heroImageView.addGestureRecognizer(tapGesture)
        resetButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
    }
    
    func setupLayout() {
        view.addSubview(scoreLabel)
        view.addSubview(bpsLabel)
        view.addSubview(cpsLabel)
        view.addSubview(heroImageView)
        view.addSubview(upgradesTableView)
        view.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            bpsLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 5),
            bpsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cpsLabel.topAnchor.constraint(equalTo: bpsLabel.bottomAnchor, constant: 3),
            cpsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            heroImageView.topAnchor.constraint(equalTo: cpsLabel.bottomAnchor, constant: 10),
            heroImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heroImageView.widthAnchor.constraint(equalToConstant: 200),
            heroImageView.heightAnchor.constraint(equalToConstant: 200),
            
            upgradesTableView.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 15),
            upgradesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            upgradesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            upgradesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            resetButton.widthAnchor.constraint(equalToConstant: 50),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func heroTapped() {
        clickCount += 1
        totalClicks += 1
        clickTimes.append(Date())
        
        animateTap()
        createParticle()
        addHapticFeedback()
    }
    
    func updateLabels() {
        scoreLabel.text = "Boogerman: \(clickCount.formatted())"
        bpsLabel.text = String(format: "Boogerman per second: %.1f", boogermanPerSecond)
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
        particle.text = ["+1", "💚", "🤢", "✨"].randomElement()!
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
            message: "This will reset everything including upgrades!",
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
        clickTimes.removeAll()
        
        for i in 0..<upgrades.count {
            upgrades[i].owned = 0
        }
        
        calculateBPS()
        saveGameData()
        updateLabels()
        upgradesTableView.reloadData()
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
        return upgrades.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UpgradeCell", for: indexPath) as! UpgradeCell
        let upgrade = upgrades[indexPath.row]
        let canAfford = clickCount >= upgrade.currentCost
        cell.configure(with: upgrade, canAfford: canAfford)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
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
