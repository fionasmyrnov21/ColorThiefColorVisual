import UIKit
import SwiftUI

final class GameViewController: UIHostingController<RootView> {
    init() { super.init(rootView: RootView()) }
    required init?(coder: NSCoder) { super.init(coder: coder, rootView: RootView()) }
    override var prefersStatusBarHidden: Bool { false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
}
