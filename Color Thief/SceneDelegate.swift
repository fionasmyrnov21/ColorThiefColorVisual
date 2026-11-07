import UIKit
import Combine
import StoreKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var startup: StartupViewModel?
    private var routeObserver: AnyCancellable?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = window ?? UIWindow(windowScene: scene)
        window.rootViewController = StartupLoadingController()
        self.window = window
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let model = delegate.startup
        startup = model
        routeObserver = model.$route.removeDuplicates().sink { [weak self] route in self?.show(route) }
        window.makeKeyAndVisible()
        Task { await model.start() }
    }

    func sceneDidBecomeActive(_ scene: UIScene) { requestReviewIfNeeded() }

    func sceneWillResignActive(_ scene: UIScene) {
        if window?.rootViewController is ContentPageController {
            Task { await ContentSession.shared.capture() }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if window?.rootViewController is ContentPageController { ContentSession.shared.saveForBackground() }
    }

    private func show(_ route: StartupRoute) {
        guard let window else { return }
        switch route {
        case .loading:
            if !(window.rootViewController is StartupLoadingController) { window.rootViewController = StartupLoadingController() }
        case .game:
            if !(window.rootViewController is GameViewController) { window.rootViewController = GameViewController() }
        case .content(let address):
            if let current = window.rootViewController as? ContentPageController, current.model.entryAddress == address { return }
            window.rootViewController = ContentPageController(model: ContentViewModel(address: address), onAppearance: { [weak self] in
                self?.requestReviewIfNeeded()
            }, openGame: { [weak self] in self?.startup?.openGame() })
        }
        window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
    }

    private func requestReviewIfNeeded() {
        guard let window, let scene = window.windowScene, scene.activationState == .foregroundActive,
              let controller = window.rootViewController as? ContentPageController,
              controller.hasAppeared, controller.viewIfLoaded?.window != nil, startup?.consumeReviewRequest() == true else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
