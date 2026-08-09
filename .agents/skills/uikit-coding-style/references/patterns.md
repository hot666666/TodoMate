# UIKit Patterns

## Contents

- File Shape
- View Construction
- Theming
- Delegates
- UIView Template
- UIViewController Template
- Dynamic Constraints
- Animations
- Screen Transitions
- Accessibility
- Cells
- Tests

## File Shape

Common order:

1. Imports
2. Protocols/delegates used by the type
3. Type declaration and conformances
4. `private struct UX` constants
5. Dependencies, callbacks, and state
6. UI elements
7. Constraint properties
8. Initializers
9. Lifecycle
10. Setup/configure/layout methods
11. Actions/delegates
12. Theming

Match the local file's `MARK` style if it already differs.

## View Construction

When available, use `.build` so `translatesAutoresizingMaskIntoConstraints` is false by default.

```swift
private lazy var titleLabel: UILabel = .build { label in
    label.adjustsFontForContentSizeCategory = true
    label.font = FXFontStyles.Bold.title2.scaledFont()
    label.numberOfLines = 0
    label.textAlignment = .left
    label.accessibilityIdentifier = AccessibilityIdentifiers.Feature.titleLabel
    label.accessibilityTraits = .header
}

private lazy var actionButton: PrimaryRoundedButton = .build { button in
    button.addTarget(self, action: #selector(self.didTapAction), for: .touchUpInside)
}
```

Use `configure` for state or view-model data:

```swift
func configure(viewModel: FeatureViewModel) {
    titleLabel.text = viewModel.title
    subtitleLabel.text = viewModel.subtitle
    actionButton.configure(viewModel: viewModel.button)
}
```

## Theming

Use `Themeable` for view controllers or owning views that listen to `.ThemeDidChange`. Use `ThemeApplicable` for reusable child views, cells, and controls that receive an already-resolved `Theme`.

`Themeable` types usually have:

```swift
final class FeatureViewController: UIViewController, Themeable {
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: UUID? { windowUUID }

    private let windowUUID: WindowUUID

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        contentView.applyTheme(theme: theme)
    }
}
```

`listenForThemeChanges` stores a cancellable and calls `applyTheme()` on the owner. It can also cascade the resolved theme into subviews that conform to `ThemeApplicable`.

Leaf views should not resolve themes themselves unless they are also the owner of a window UUID and theme listener. Prefer:

```swift
final class FeatureContentView: UIView, ThemeApplicable {
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        actionButton.applyTheme(theme: theme)
    }
}
```

Use `InjectedThemeUUIDIdentifiable` for a view that must resolve a window UUID before it is installed in a window hierarchy, or for table views whose delegate supplies the UUID.

Rules:

- Resolve theme once per `applyTheme()` and pass it down.
- Keep `configure(...)` for content/state and `applyTheme(...)` for colors/images that change with theme.
- Do not call `listenForThemeChanges` repeatedly; call it once in lifecycle setup.
- If private-mode theming is a feature, use the existing private override hooks rather than hard-coded colors.

## Delegates

Declare a delegate when a reusable child view must report user intent without owning the business logic, navigation, store dispatch, or parent state. Use a closure for one or two private callbacks on a non-reusable object; use a delegate for multiple related events, reusable UIKit views/cells, or coordinator communication.

Delegate conventions:

- Mark UI delegates `@MainActor` when callbacks touch UI.
- Constrain class-only delegates with `AnyObject`.
- Store delegates as `weak var delegate`.
- Name callbacks from the child view's point of view: `featureContentViewDidTapAction(_:)`, `badCertContentViewDidTapProceed()`.
- Let the parent view controller or coordinator translate callbacks into Redux actions, navigation, telemetry, or service calls.

```swift
@MainActor
protocol FeatureContentViewDelegate: AnyObject {
    func featureContentViewDidTapPrimaryAction(_ view: FeatureContentView)
    func featureContentViewDidTapLearnMore(_ view: FeatureContentView)
}

final class FeatureContentView: UIView {
    weak var delegate: FeatureContentViewDelegate?

    @objc
    private func didTapPrimaryAction() {
        delegate?.featureContentViewDidTapPrimaryAction(self)
    }
}

final class FeatureViewController: UIViewController, FeatureContentViewDelegate {
    func featureContentViewDidTapPrimaryAction(_ view: FeatureContentView) {
        store.dispatch(FeatureAction(windowUUID: windowUUID, actionType: FeatureActionType.didTapPrimaryAction))
    }

    func featureContentViewDidTapLearnMore(_ view: FeatureContentView) {
        coordinator?.showLearnMore()
    }
}
```

Use coordinator delegates for flow completion or parent navigation:

```swift
protocol FeatureCoordinatorDelegate: AnyObject {
    func didFinishFeature(from coordinator: FeatureCoordinator)
}

final class FeatureCoordinator: BaseCoordinator {
    weak var parentCoordinator: FeatureCoordinatorDelegate?

    private func didFinish() {
        parentCoordinator?.didFinishFeature(from: self)
    }
}
```

Use view delegates for view events; use coordinator delegates for flow events. Avoid making a child view call `present`, `push`, or global store dispatch directly unless that is already the established local pattern.

## UIView Template

```swift
@MainActor
protocol FeatureContentViewDelegate: AnyObject {
    func featureContentViewDidTapAction()
}

final class FeatureContentView: UIView, ThemeApplicable {
    private struct UX {
        static let spacing: CGFloat = 16
        static let buttonHeight: CGFloat = 44
    }

    weak var delegate: FeatureContentViewDelegate?

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.spacing
    }

    private lazy var actionButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapAction), for: .touchUpInside)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        stackView.addArrangedSubview(actionButton)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
        ])
    }

    func configure(viewModel: PrimaryRoundedButtonViewModel) {
        actionButton.configure(viewModel: viewModel)
    }

    @objc
    private func didTapAction() {
        delegate?.featureContentViewDidTapAction()
    }

    func applyTheme(theme: Theme) {
        actionButton.applyTheme(theme: theme)
    }
}
```

## UIViewController Template

```swift
final class FeatureViewController: UIViewController, Themeable {
    private struct UX {
        static let horizontalPadding: CGFloat = 32
        static let stackSpacing: CGFloat = 24
    }

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: UUID? { windowUUID }

    private let windowUUID: WindowUUID
    private let viewModel: FeatureViewModel

    private lazy var scrollView: UIScrollView = .build()

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.stackSpacing
    }

    init(
        windowUUID: WindowUUID,
        viewModel: FeatureViewModel,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configure()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    private func setupLayout() {
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: UX.horizontalPadding
            ),
            stackView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -UX.horizontalPadding
            ),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -(UX.horizontalPadding * 2)
            )
        ])
    }

    private func configure() {
        title = viewModel.title
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }
}
```

## Dynamic Constraints

For orientation or dynamic-type variants, keep common constraints and variant constraints separate:

```swift
private var commonConstraints = [NSLayoutConstraint]()
private var compactConstraints = [NSLayoutConstraint]()
private var regularConstraints = [NSLayoutConstraint]()

func adjustConstraints() {
    NSLayoutConstraint.deactivate(commonConstraints + compactConstraints + regularConstraints)

    commonConstraints = [
        container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ]

    compactConstraints = [
        container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
    ]

    regularConstraints = [
        container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        container.widthAnchor.constraint(equalToConstant: 480)
    ]

    NSLayoutConstraint.activate(commonConstraints)
    NSLayoutConstraint.activate(isCompact ? compactConstraints : regularConstraints)
}
```

For orientation transitions, update constraints with the transition coordinator so the layout change stays synchronized with UIKit:

```swift
override func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { _ in
        self.adjustConstraints()
        self.view.layoutIfNeeded()
    }
}
```

## Animations

Keep animations near the view state they animate. Use `UIView.animate` for alpha, transforms, and constraint constants. Call `layoutIfNeeded()` inside the animation block when animating constraints.

```swift
private func setExpanded(_ isExpanded: Bool, animated: Bool) {
    let updates = {
        self.contentStack.isHidden = !isExpanded
        self.chevron.transform = isExpanded
            ? CGAffineTransform(rotationAngle: .pi / 2)
            : .identity
        self.layoutIfNeeded()
    }

    if animated {
        UIView.animate(withDuration: 0.3, animations: updates)
    } else {
        updates()
    }
}
```

Use `UIView.transition` for cross-dissolve table or collection reloads when the visual change is state replacement rather than movement:

```swift
UIView.transition(
    with: tableView,
    duration: 0.2,
    options: .transitionCrossDissolve,
    animations: {
        tableView.reloadData()
    }
)
```

Use a dedicated animator object for gesture-driven or reusable animations:

```swift
@MainActor
protocol FeatureSwipeAnimatorDelegate: AnyObject {
    func featureSwipeAnimatorDidFinish(_ animator: FeatureSwipeAnimator)
    func featureSwipeAnimatorCanAnimateAway(_ animator: FeatureSwipeAnimator) -> Bool
}

final class FeatureSwipeAnimator: NSObject, UIGestureRecognizerDelegate {
    weak var delegate: FeatureSwipeAnimatorDelegate?
    weak var animatingView: UIView?

    func animateBackToCenter() {
        UIView.animate(withDuration: 0.15) {
            self.animatingView?.transform = .identity
            self.animatingView?.alpha = 1
        }
    }
}
```

## Screen Transitions

Prefer the coordinator/router layer for screen transitions. View controllers and views should report intent; coordinators decide whether to `present`, `push`, `dismiss`, or handle a route.

Coordinator shape:

```swift
final class FeatureCoordinator: BaseCoordinator, ParentCoordinatorDelegate {
    weak var parentCoordinator: ParentCoordinatorDelegate?

    func start() {
        let viewController = FeatureViewController()
        viewController.coordinator = self
        router.push(viewController) { [weak self] in
            guard let self else { return }
            self.parentCoordinator?.didFinish(from: self)
        }
    }

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }
}
```

Use custom transitions when the presentation animation is part of the feature. Implement `UIViewControllerAnimatedTransitioning` and `UIViewControllerTransitioningDelegate`, then pass the transition through the router or set it before presentation.

```swift
final class FeatureAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var presenting = false
    private let duration: TimeInterval = 0.35

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        toView.alpha = 0
        container.addSubview(toView)

        UIView.animate(withDuration: duration) {
            toView.alpha = 1
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }
}

extension FeatureAnimator: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}
```

Rules:

- Keep view-local animations in the view or view controller.
- Keep navigation and presentation decisions in coordinators.
- Store child coordinators while flows are active and remove them on completion.
- Use router completion callbacks for pushed view-controller cleanup when the local router supports it.

## Accessibility

Use centralized identifiers:

```swift
label.accessibilityIdentifier = AccessibilityIdentifiers.Feature.titleLabel
button.accessibilityIdentifier = AccessibilityIdentifiers.Feature.primaryButton
```

Add identifiers at creation time for static elements. For reusable component libraries, prefer passing the identifier in a view model and applying it inside `configure`.

## Cells

For reusable cells:

- Reset text, images, accessory views, and added subviews in `prepareForReuse`.
- Keep `configure(viewModel:)` side-effect-light.
- Apply theme separately from configure when theme can change independently.

```swift
override func prepareForReuse() {
    super.prepareForReuse()
    textLabel?.text = nil
    detailTextLabel?.text = nil
    accessoryView = nil
    accessoryType = .none
    imageView?.image = nil
    contentView.subviews.forEach { $0.removeFromSuperview() }
}
```

## Tests

When changing view behavior, prefer focused XCTest coverage around view models, state, delegates, or view controller wiring. For UI-test-facing changes, add or update accessibility identifiers and matching selectors/page objects.
