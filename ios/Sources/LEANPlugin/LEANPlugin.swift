import Foundation
import Capacitor
import LeanSDK
import UIKit

public class LEANPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "Lean"
    public let jsName = "Lean"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "link", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reconnect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "createPaymentSource", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updatePaymentSource", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pay", returnType: CAPPluginReturnPromise)
    ]

    private let setupWarmupDelay: TimeInterval = 0.2
    private var lastSetupKey: String?

    private static func mapCountry(_ country: String?) -> LeanCountry {
        guard let c = country?.lowercased(), !c.isEmpty else { return .SaudiArabia }
        switch c {
        case "sa": return .SaudiArabia
        default: return .SaudiArabia
        }
    }

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

    private static func resultFrom(status: LeanStatus?, debugContext: [String: Any]? = nil) -> [String: Any] {
        guard let status = status else {
            var fallback: [String: Any] = [
                "status": "SUCCESS",
                "message": "Operation completed"
            ]
            if let debugContext = debugContext {
                fallback["debug_context"] = debugContext
            }
            return fallback
        }

        var out: [String: Any] = [
            "status": String(describing: status.status),
            "message": status.message ?? "",
            "method": status.method,
            "last_api_response": status.lastApiResponse ?? "",
            "exit_point": status.exitPoint ?? "",
            "secondary_status": status.secondaryStatus ?? ""
        ]
        if let bank = status.bankDetails {
            out["bank"] = [
                "bank_identifier": bank.bankIdentifier as Any,
                "is_supported": bank.isSupported as Any
            ]
        } else {
            out["bank"] = [
                "bank_identifier": NSNull(),
                "is_supported": NSNull()
            ]
        }
        if let debugContext = debugContext {
            out["debug_context"] = debugContext
        }
        return out
    }

    private static func normalizedRequiredString(_ call: CAPPluginCall, _ key: String) -> String? {
        guard let raw = call.getString(key) else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func normalizedOptionalString(_ call: CAPPluginCall, _ key: String) -> String? {
        guard let raw = call.getString(key) else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func setupIfNeeded(
        call: CAPPluginCall,
        appToken: String?,
        sandbox: Bool,
        country: String?,
        completion: @escaping () -> Void
    ) {
        guard let token = appToken, !token.isEmpty else {
            guard self.lastSetupKey != nil else {
                call.reject("appToken is required for iOS Lean initialization")
                return
            }
            completion()
            return
        }

        let resolvedCountry = LEANPlugin.mapCountry(country)
        let setupKey = "\(token)|\(sandbox)|\(resolvedCountry.rawValue)"
        let requiresWarmup = self.lastSetupKey != setupKey
        Lean.manager.setup(appToken: token, sandbox: sandbox, version: "latest", country: resolvedCountry, debug:true)
        self.lastSetupKey = setupKey
        if requiresWarmup {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.setupWarmupDelay, execute: completion)
        } else {
            completion()
        }
    }

    private func resolveViewController(_ call: CAPPluginCall) -> UIViewController? {
        guard let viewController = self.bridge?.viewController else {
            call.reject("View controller not available")
            return nil
        }
        return viewController
    }

    @objc func link(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
            return
        }
        let permissions = LEANPlugin.mapPermissions(call.getArray("permissions") as? [String])
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let bankId = LEANPlugin.normalizedOptionalString(call, "bankIdentifier")
        let failRedirectUrl = LEANPlugin.normalizedOptionalString(call, "failRedirectUrl")
        let successRedirectUrl = LEANPlugin.normalizedOptionalString(call, "successRedirectUrl")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let resolvedPermissions = permissions.isEmpty ? [LeanPermission.Identity, .Accounts, .Transactions, .Balance] : permissions
                let context: [String: Any] = [
                    "method": "link",
                    "customer_id": customerId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.link(
                    presentingViewController: viewController,
                    customerId: customerId,
                    permissions: resolvedPermissions,
                    bankId: bankId,
                    customization: nil,
                    failRedirectUrl: failRedirectUrl,
                    successRedirectUrl: successRedirectUrl,
                    success: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    },
                    error: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    }
                )
            }
        }
    }

    @objc func connect(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
            return
        }
        let permissions = LEANPlugin.mapPermissions(call.getArray("permissions") as? [String])
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let bankId = LEANPlugin.normalizedOptionalString(call, "bankIdentifier")
        let paymentDestinationId = LEANPlugin.normalizedOptionalString(call, "paymentDestinationId")
        let failRedirectUrl = LEANPlugin.normalizedOptionalString(call, "failRedirectUrl")
        let successRedirectUrl = LEANPlugin.normalizedOptionalString(call, "successRedirectUrl")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let resolvedPermissions = permissions.isEmpty ? [LeanPermission.Identity, .Accounts, .Transactions, .Balance] : permissions
                let context: [String: Any] = [
                    "method": "connect",
                    "customer_id": customerId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.connect(
                    presentingViewController: viewController,
                    customerId: customerId,
                    permissions: resolvedPermissions,
                    paymentDestinationId: paymentDestinationId,
                    bankId: bankId,
                    customization: nil,
                    failRedirectUrl: failRedirectUrl,
                    successRedirectUrl: successRedirectUrl,
                    success: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    },
                    error: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    }
                )
            }
        }
    }

    @objc func reconnect(_ call: CAPPluginCall) {
        guard let reconnectId = LEANPlugin.normalizedRequiredString(call, "reconnectId") else {
            call.reject("reconnectId is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "reconnect",
                    "reconnect_id": reconnectId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.reconnect(
                    presentingViewController: viewController,
                    reconnectId: reconnectId,
                    customization: nil,
                    success: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    },
                    error: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    }
                )
            }
        }
    }

    @objc func createPaymentSource(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let bankId = LEANPlugin.normalizedOptionalString(call, "bankIdentifier")
        let paymentDestinationId = LEANPlugin.normalizedOptionalString(call, "paymentDestinationId")
        let failRedirectUrl = LEANPlugin.normalizedOptionalString(call, "failRedirectUrl")
        let successRedirectUrl = LEANPlugin.normalizedOptionalString(call, "successRedirectUrl")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "createPaymentSource",
                    "customer_id": customerId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.createPaymentSource(
                    presentingViewController: viewController,
                    customerId: customerId,
                    bankId: bankId,
                    paymentDestinationId: paymentDestinationId,
                    customization: nil,
                    failRedirectUrl: failRedirectUrl,
                    successRedirectUrl: successRedirectUrl,
                    success: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    },
                    error: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    }
                )
            }
        }
    }

    @objc func updatePaymentSource(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
            return
        }
        guard let paymentSourceId = LEANPlugin.normalizedRequiredString(call, "paymentSourceId") else {
            call.reject("paymentSourceId is required")
            return
        }
        guard let paymentDestinationId = LEANPlugin.normalizedRequiredString(call, "paymentDestinationId") else {
            call.reject("paymentDestinationId is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "updatePaymentSource",
                    "customer_id": customerId,
                    "payment_source_id": paymentSourceId,
                    "payment_destination_id": paymentDestinationId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.updatePaymentSource(
                    presentingViewController: viewController,
                    customerId: customerId,
                    paymentSourceId: paymentSourceId,
                    paymentDestinationId: paymentDestinationId,
                    customization: nil,
                    success: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    },
                    error: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    }
                )
            }
        }
    }

    @objc func pay(_ call: CAPPluginCall) {
        guard let paymentIntentId = LEANPlugin.normalizedRequiredString(call, "paymentIntentId") else {
            call.reject("paymentIntentId is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let accountId = LEANPlugin.normalizedOptionalString(call, "accountId")
        let failRedirectUrl = LEANPlugin.normalizedOptionalString(call, "failRedirectUrl")
        let successRedirectUrl = LEANPlugin.normalizedOptionalString(call, "successRedirectUrl")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "pay",
                    "payment_intent_id": paymentIntentId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.pay(
                    presentingViewController: viewController,
                    paymentIntentId: paymentIntentId,
                    accountId: accountId,
                    customization: nil,
                    failRedirectUrl: failRedirectUrl,
                    successRedirectUrl: successRedirectUrl,
                    success: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    },
                    error: { status in
                        call.resolve(LEANPlugin.resultFrom(status: status, debugContext: context))
                    }
                )
            }
        }
    }
}
