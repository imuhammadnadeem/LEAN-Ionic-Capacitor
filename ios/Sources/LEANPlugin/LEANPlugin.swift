import Foundation
import Capacitor
import LeanSDK

/// Capacitor plugin bridging to Lean Link iOS SDK.
/// Call Lean.manager.setup(appToken, sandbox) in your app's init, or pass appToken in connect options.
@objc(LeanPlugin)
public class LEANPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LeanPlugin"
    public let jsName = "Lean"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise)
    ]

    private static func mapPermissions(_ permissions: [String]?) -> [LeanPermission] {
        guard let permissions = permissions else { return [] }
        return permissions.compactMap { permission in
            switch permission.lowercased() {
            case "identity": return .Identity
            case "accounts": return .Accounts
            case "transactions": return .Transactions
            case "balance": return .Balance
            case "payments": return .Payments
            default: return nil
            }
        }
    }

    private static func resultFrom(status: LeanStatus?) -> [String: Any] {
        guard let status = status else {
            return ["status": "SUCCESS", "message": "Entity connected"]
        }
        var out: [String: Any] = [
            "status": String(describing: status.status),
            "message": status.message ?? ""
        ]
        out["method"] = status.method
        return out
    }

    @objc func connect(_ call: CAPPluginCall) {
        guard let customerId = call.getString("customerId"), !customerId.isEmpty else {
            call.reject("customerId is required")
            return
        }
        let permissions = LEANPlugin.mapPermissions(call.getArray("permissions") as? [String])
        let sandbox = call.getBool("sandbox") ?? true
        let appToken = call.getString("appToken")
        let bankId = call.getString("bankIdentifier")
        let paymentDestinationId = call.getString("paymentDestinationId")

        if let token = appToken, !token.isEmpty {
            Lean.manager.setup(appToken: token, sandbox: sandbox, version: "latest")
        }

        guard let viewController = bridge?.viewController else {
            call.reject("View controller not available")
            return
        }

        let resolvedPermissions = permissions.isEmpty ? [LeanPermission.Identity, .Accounts, .Transactions, .Balance] : permissions
        Lean.manager.connect(
            presentingViewController: viewController,
            customerId: customerId,
            permissions: resolvedPermissions,
            paymentDestinationId: paymentDestinationId,
            bankId: bankId,
            customization: nil,
            success: { _ in
                call.resolve(LEANPlugin.resultFrom(status: nil))
            },
            error: { status in
                call.resolve(LEANPlugin.resultFrom(status: status))
            }
        )
    }
}
