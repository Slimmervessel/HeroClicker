import UIKit

class ViewController: UIViewController {
    
    var clickCount: Int = 0 {
        didSet { UserDefaults.standard.set(clickCount, forKey: "clickCount") }
    }
    var totalClicks: Int = 0 {
        didSet { UserDefaults.standard.set(totalClicks, forKey: "totalClicks") }
    }
    var clickTimes: [Date] = []
    var cpsTimer: Timer?
    
    let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 36)
        label.textAlignment = .center
        label.textColor = .white
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 2, height: 2)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let cpsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .yellow
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let totalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🔄 Reset", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clickCount = UserDefaults.standard.integer(forKey: "clickCount")
        totalClicks = UserDefaults.standard.integer(forKey: "totalClicks")
        
        setupBackground()
        setupImage()
        setupLayout()
        setupGestures()
        updateLabels()
        startCPSTimer()
    }
    
    func setupBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.8, green: 0.5, blue: 0.1, alpha: 1).cgColor,
            UIColor(red: 0.6, green: 0.35, blue: 0.05, alpha: 1).cgColor,
            UIColor(red: 0.4, green: 0.25, blue: 0.05, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setupImage() {
        if let image = UIImage(named: "hero") {
            heroImageView.image = image
        } else {
            heroImageView.backgroundColor = UIColor.green.withAlphaComponent(0.3)
            heroImageView.layer.cornerRadius = 20
            heroImageView.layer.borderWidth = 3
            heroImageView.layer.borderColor = UIColor.yellow.cgColor
            
            let label = UILabel()
            label.text = "B"
            label.font = UIFont.boldSystemFont(ofSize: 120)
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
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(heroTapped))
        heroImageView.addGestureRecognizer(tapGesture)
        resetButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
    }
    
    func setupLayout() {
        view.addSubview(heroImageView)
        view.addSubview(scoreLabel)
        view.addSubview(cpsLabel)
        view.addSubview(totalLabel)
        view.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            cpsLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 10),
            cpsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            totalLabel.topAnchor.constraint(equalTo: cpsLabel.bottomAnchor, constant: 5),
            totalLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            heroImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heroImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            heroImageView.widthAnchor.constraint(equalToConstant: 280),
            heroImageView.heightAnchor.constraint(equalToConstant: 380),
            
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 140),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func heroTapped() {
        clickCount += 1
        totalClicks += 1
        clickTimes.append(Date())
        
        updateLabels()
        animateTap()
        createParticle()
        addHapticFeedback()
    }
    
    func updateLabels() {
        scoreLabel.text = "⭐️ \(clickCount.formatted()) ⭐️"
        totalLabel.text = "Total: \(totalClicks.formatted())"
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
        particle.text = ["+1", "💥", "⚡️", "✨"].randomElement()!
        particle.font = UIFont.boldSystemFont(ofSize: 28)
        particle.textColor = .yellow
        particle.shadowColor = .black
        particle.shadowOffset = CGSize(width: 1, height: 1)
        
        let randomX = heroImageView.center.x + CGFloat.random(in: -60...60)
        particle.center = CGPoint(x: randomX, y: heroImageView.center.y)
        view.addSubview(particle)
        
        UIView.animate(withDuration: 1.2, delay: 0, options: .curveEaseOut, animations: {
            particle.center.y -= 120
            particle.alpha = 0
            particle.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { _ in
            particle.removeFromSuperview()
        }
    }
    
    func addHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func startCPSTimer() {
        cpsTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCPS()
        }
    }
    
    func updateCPS() {
        let now = Date()
        clickTimes = clickTimes.filter { now.timeIntervalSince($0) <= 1.0 }
        let cps = Double(clickTimes.count)
        cpsLabel.text = String(format: "⚡️ %.1f CPS", cps)
    }
    
    @objc func resetGame() {
        let alert = UIAlertController(
            title: "Reset Game?",
            message: "This will reset your score to 0. Total clicks will also be reset.",
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
        updateLabels()
        cpsLabel.text = "⚡️ 0.0 CPS"
        
        UIView.animate(withDuration: 0.3) {
            self.heroImageView.transform = CGAffineTransform(rotationAngle: .pi * 2)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    deinit {
        cpsTimer?.invalidate()
    }
}

extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}