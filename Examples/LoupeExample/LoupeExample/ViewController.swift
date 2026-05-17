import UIKit

struct ExampleItem {
    let index: Int
    let title: String
    let subtitle: String
    let status: String
}

final class ViewController: UITableViewController {
    private let allItems: [ExampleItem] = (1...80).map {
        ExampleItem(
            index: $0,
            title: "Customer \($0)",
            subtitle: $0.isMultiple(of: 3) ? "Needs follow-up" : "Ready for review",
            status: $0.isMultiple(of: 2) ? "Open" : "Draft"
        )
    }

    private var visibleItems: [ExampleItem] = []
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Loupe Workbench"
        visibleItems = allItems
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Form",
            style: .plain,
            target: self,
            action: #selector(openForm)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "example.openForm"

        tableView.register(ExampleCell.self, forCellReuseIdentifier: ExampleCell.reuseIdentifier)
        tableView.accessibilityIdentifier = "example.customerList"
        tableView.rowHeight = 76

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search customers"
        searchController.searchBar.accessibilityIdentifier = "example.search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleItems.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExampleCell.reuseIdentifier,
            for: indexPath
        ) as! ExampleCell
        cell.configure(item: visibleItems[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(
            DetailViewController(item: visibleItems[indexPath.row]),
            animated: true
        )
    }

    @objc private func openForm() {
        let controller = UINavigationController(rootViewController: FormViewController())
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true)
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !query.isEmpty else {
            visibleItems = allItems
            tableView.reloadData()
            return
        }

        visibleItems = allItems.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.subtitle.localizedCaseInsensitiveContains(query)
                || $0.status.localizedCaseInsensitiveContains(query)
        }
        tableView.reloadData()
    }
}

final class ExampleCell: UITableViewCell {
    static let reuseIdentifier = "ExampleCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let badgeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: ExampleItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        badgeLabel.text = item.status
        accessibilityIdentifier = "example.customer.\(item.index)"
        titleLabel.accessibilityIdentifier = "example.customer.\(item.index).title"
        subtitleLabel.accessibilityIdentifier = "example.customer.\(item.index).subtitle"
        badgeLabel.accessibilityIdentifier = "example.customer.\(item.index).status"
    }

    private func configure() {
        accessoryType = .disclosureIndicator

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        badgeLabel.font = .preferredFont(forTextStyle: .caption1)
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = .tertiarySystemFill
        badgeLabel.layer.cornerRadius = 6
        badgeLabel.layer.masksToBounds = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [textStack, badgeLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            badgeLabel.widthAnchor.constraint(equalToConstant: 58),
            badgeLabel.heightAnchor.constraint(equalToConstant: 26),
        ])
    }
}

final class DetailViewController: UIViewController {
    private let item: ExampleItem
    private let gestureCard = UIView()
    private let gestureStatus = UILabel()
    private var panOffset: CGFloat = 0

    init(item: ExampleItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = item.title
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "example.detail"
        configureLayout()
        configureGesture()
    }

    private func configureLayout() {
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.accessibilityIdentifier = "example.detail.title"

        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(item.subtitle) - \(item.status)"
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.accessibilityIdentifier = "example.detail.subtitle"

        gestureCard.backgroundColor = .systemIndigo
        gestureCard.layer.cornerRadius = 18
        gestureCard.accessibilityIdentifier = "example.gestureCard"

        let cardLabel = UILabel()
        cardLabel.text = "Swipe this card"
        cardLabel.textColor = .white
        cardLabel.font = .preferredFont(forTextStyle: .headline)
        cardLabel.textAlignment = .center
        cardLabel.translatesAutoresizingMaskIntoConstraints = false
        cardLabel.accessibilityIdentifier = "example.gestureCard.label"
        gestureCard.addSubview(cardLabel)

        gestureStatus.text = "Offset 0"
        gestureStatus.font = .preferredFont(forTextStyle: .body)
        gestureStatus.accessibilityIdentifier = "example.gestureStatus"

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, gestureCard, gestureStatus])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            gestureCard.heightAnchor.constraint(equalToConstant: 160),
            cardLabel.centerXAnchor.constraint(equalTo: gestureCard.centerXAnchor),
            cardLabel.centerYAnchor.constraint(equalTo: gestureCard.centerYAnchor),
        ])
    }

    private func configureGesture() {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gestureCard.addGestureRecognizer(recognizer)
        gestureCard.isUserInteractionEnabled = true
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let nextOffset = panOffset + translation.x
        gestureCard.transform = CGAffineTransform(translationX: nextOffset, y: 0)
        gestureStatus.text = "Offset \(Int(nextOffset))"
        recognizer.setTranslation(.zero, in: view)

        if recognizer.state == .ended || recognizer.state == .cancelled {
            panOffset = nextOffset
        }
    }
}

final class FormViewController: UIViewController {
    private let nameField = UITextField()
    private let noteField = UITextView()
    private let saveButton = UIButton(type: .system)
    private let resultLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "New Record"
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "example.form"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(close)
        )
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "example.form.cancel"

        configureControls()
        layoutControls()
    }

    private func configureControls() {
        nameField.placeholder = "Name"
        nameField.borderStyle = .roundedRect
        nameField.returnKeyType = .done
        nameField.delegate = self
        nameField.accessibilityIdentifier = "example.form.name"

        noteField.font = .preferredFont(forTextStyle: .body)
        noteField.layer.borderColor = UIColor.separator.cgColor
        noteField.layer.borderWidth = 1
        noteField.layer.cornerRadius = 8
        noteField.accessibilityIdentifier = "example.form.note"

        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.backgroundColor = .systemGreen
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 12
        saveButton.accessibilityIdentifier = "example.form.save"
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        resultLabel.text = "Not saved"
        resultLabel.font = .preferredFont(forTextStyle: .body)
        resultLabel.accessibilityIdentifier = "example.form.result"
    }

    private func layoutControls() {
        let stack = UIStackView(arrangedSubviews: [nameField, noteField, saveButton, resultLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            noteField.heightAnchor.constraint(equalToConstant: 140),
            saveButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    @objc private func save() {
        let name = nameField.text?.isEmpty == false ? nameField.text! : "Untitled"
        resultLabel.text = "Saved \(name)"
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

extension FormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
