// swiftlint:disable file_length type_body_length
import Foundation
import Capacitor
import LeanSDK
import UIKit

@objc(LeanPlugin)
public class LEANPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LeanPlugin"
    public let jsName = "Lean"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "link", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reconnect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "createPaymentSource", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updatePaymentSource", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pay", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "verifyAddress", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "authorizeConsent", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "checkout", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "manageConsents", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "captureRedirect", returnType: CAPPluginReturnPromise)
    ]

    private let setupWarmupDelay: TimeInterval = 0.2
    private var lastSetupKey: String?

    private static func mapCountry(_ country: String?) -> LeanCountry {
        guard let countryCode = country?.lowercased(), !countryCode.isEmpty else { return .SaudiArabia }
        switch countryCode {
        case "sa", "ksa": return .SaudiArabia
        case "ae", "uae": return .UnitedArabEmirates
        default: return .SaudiArabia
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func mapPermissions(_ permissions: [String]?) -> [LeanPermission] {
        guard let permissions = permissions else { return [] }
        return permissions.compactMap { permission in
            switch permission.lowercased() {
            case "identity": return .Identity
            case "identities": return .Identities
            case "accounts": return .Accounts
            case "transactions": return .Transactions
            case "balance": return .Balance
            case "payments": return .Payments
            case "beneficiaries": return .Beneficiaries
            case "directdebits", "direct_debits": return .DirectDebits
            case "standingorders", "standing_orders": return .StandingOrders
            case "scheduledpayments", "scheduled_payments": return .ScheduledPayments
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
        Lean.manager.setup(appToken: token, sandbox: sandbox, version: "latest", country: resolvedCountry, debug: true)
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
                    accessToken: accessToken,
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

    // swiftlint:disable:next function_body_length
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
        let accountType = LEANPlugin.normalizedOptionalString(call, "accountType")
        let endUserId = LEANPlugin.normalizedOptionalString(call, "endUserId")
        let accessTo = LEANPlugin.normalizedOptionalString(call, "accessTo")
        let accessFrom = LEANPlugin.normalizedOptionalString(call, "accessFrom")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")
        let showConsentExplanation = call.getBool("showConsentExplanation")
        let destinationAlias = LEANPlugin.normalizedOptionalString(call, "destinationAlias")
        let destinationAvatar = LEANPlugin.normalizedOptionalString(call, "destinationAvatar")
        let customerMetadata = LEANPlugin.normalizedOptionalString(call, "customerMetadata")

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
                    accountType: accountType,
                    endUserId: endUserId,
                    accessTo: accessTo,
                    accessFrom: accessFrom,
                    accessToken: accessToken,
                    showConsentExplanation: showConsentExplanation,
                    destinationAlias: destinationAlias,
                    destinationAvatar: destinationAvatar,
                    customerMetadata: customerMetadata,
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
        let destinationAlias = LEANPlugin.normalizedOptionalString(call, "destinationAlias")
        let destinationAvatar = LEANPlugin.normalizedOptionalString(call, "destinationAvatar")

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
                    accessToken: accessToken,
                    destinationAlias: destinationAlias,
                    destinationAvatar: destinationAvatar,
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
        let destinationAlias = LEANPlugin.normalizedOptionalString(call, "destinationAlias")
        let destinationAvatar = LEANPlugin.normalizedOptionalString(call, "destinationAvatar")

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
                    accessToken: accessToken,
                    destinationAlias: destinationAlias,
                    destinationAvatar: destinationAvatar,
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

    // swiftlint:disable:next function_body_length
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
        let endUserId = LEANPlugin.normalizedOptionalString(call, "endUserId")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")
        let entityId = LEANPlugin.normalizedOptionalString(call, "entityId")
        let destinationAlias = LEANPlugin.normalizedOptionalString(call, "destinationAlias")
        let destinationAvatar = LEANPlugin.normalizedOptionalString(call, "destinationAvatar")

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
                    endUserId: endUserId,
                    accessToken: accessToken,
                    entityId: entityId,
                    destinationAlias: destinationAlias,
                    destinationAvatar: destinationAvatar,
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

    // swiftlint:disable:next function_body_length
    @objc func pay(_ call: CAPPluginCall) {
        let paymentIntentId = LEANPlugin.normalizedOptionalString(call, "paymentIntentId")
        let bulkPaymentIntentId = LEANPlugin.normalizedOptionalString(call, "bulkPaymentIntentId")
        if paymentIntentId == nil && bulkPaymentIntentId == nil {
            call.reject("paymentIntentId or bulkPaymentIntentId is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let accountId = LEANPlugin.normalizedOptionalString(call, "accountId")
        let bankId = LEANPlugin.normalizedOptionalString(call, "bankIdentifier")
        let endUserId = LEANPlugin.normalizedOptionalString(call, "endUserId")
        let failRedirectUrl = LEANPlugin.normalizedOptionalString(call, "failRedirectUrl")
        let successRedirectUrl = LEANPlugin.normalizedOptionalString(call, "successRedirectUrl")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")
        let destinationAlias = LEANPlugin.normalizedOptionalString(call, "destinationAlias")
        let destinationAvatar = LEANPlugin.normalizedOptionalString(call, "destinationAvatar")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "pay",
                    "payment_intent_id": paymentIntentId as Any,
                    "bulk_payment_intent_id": bulkPaymentIntentId as Any,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.pay(
                    presentingViewController: viewController,
                    paymentIntentId: paymentIntentId,
                    bulkPaymentIntentId: bulkPaymentIntentId,
                    accountId: accountId,
                    bankId: bankId,
                    customization: nil,
                    endUserId: endUserId,
                    failRedirectUrl: failRedirectUrl,
                    successRedirectUrl: successRedirectUrl,
                    accessToken: accessToken,
                    destinationAlias: destinationAlias,
                    destinationAvatar: destinationAvatar,
                    riskDetails: nil,
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

    @objc func verifyAddress(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
            return
        }
        guard let customerName = LEANPlugin.normalizedRequiredString(call, "customerName") else {
            call.reject("customerName is required")
            return
        }
        let permissions = LEANPlugin.mapPermissions(call.getArray("permissions") as? [String])
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")
        let destinationAlias = LEANPlugin.normalizedOptionalString(call, "destinationAlias")
        let destinationAvatar = LEANPlugin.normalizedOptionalString(call, "destinationAvatar")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let resolvedPermissions = permissions.isEmpty ? [LeanPermission.Identity] : permissions
                let context: [String: Any] = [
                    "method": "verifyAddress",
                    "customer_id": customerId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.verifyAddress(
                    presentingViewController: viewController,
                    customerId: customerId,
                    customerName: customerName,
                    permissions: resolvedPermissions,
                    customization: nil,
                    accessToken: accessToken,
                    destinationAlias: destinationAlias,
                    destinationAvatar: destinationAvatar,
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

    // swiftlint:disable:next function_body_length
    @objc func authorizeConsent(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
            return
        }
        guard let consentId = LEANPlugin.normalizedRequiredString(call, "consentId") else {
            call.reject("consentId is required")
            return
        }
        guard let failRedirectUrl = LEANPlugin.normalizedRequiredString(call, "failRedirectUrl") else {
            call.reject("failRedirectUrl is required")
            return
        }
        guard let successRedirectUrl = LEANPlugin.normalizedRequiredString(call, "successRedirectUrl") else {
            call.reject("successRedirectUrl is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")
        let destinationAlias = LEANPlugin.normalizedOptionalString(call, "destinationAlias")
        let destinationAvatar = LEANPlugin.normalizedOptionalString(call, "destinationAvatar")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "authorizeConsent",
                    "customer_id": customerId,
                    "consent_id": consentId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.authorizeConsent(
                    presentingViewController: viewController,
                    customerId: customerId,
                    consentId: consentId,
                    failRedirectUrl: failRedirectUrl,
                    successRedirectUrl: successRedirectUrl,
                    customization: nil,
                    accessToken: accessToken,
                    destinationAlias: destinationAlias,
                    destinationAvatar: destinationAvatar,
                    riskDetails: nil,
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

    @objc func checkout(_ call: CAPPluginCall) {
        guard let paymentIntentId = LEANPlugin.normalizedRequiredString(call, "paymentIntentId") else {
            call.reject("paymentIntentId is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let customerName = LEANPlugin.normalizedOptionalString(call, "customerName")
        let bankId = LEANPlugin.normalizedOptionalString(call, "bankIdentifier")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")
        let successRedirectUrl = LEANPlugin.normalizedOptionalString(call, "successRedirectUrl")
        let failRedirectUrl = LEANPlugin.normalizedOptionalString(call, "failRedirectUrl")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "checkout",
                    "payment_intent_id": paymentIntentId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.checkout(
                    presentingViewController: viewController,
                    paymentIntentId: paymentIntentId,
                    customization: nil,
                    customerName: customerName,
                    bankId: bankId,
                    accessToken: accessToken,
                    successRedirectUrl: successRedirectUrl,
                    failRedirectUrl: failRedirectUrl,
                    riskDetails: nil,
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

    @objc func manageConsents(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
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
                    "method": "manageConsents",
                    "customer_id": customerId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.manageConsents(
                    presentingViewController: viewController,
                    customerId: customerId,
                    customization: nil,
                    accessToken: accessToken,
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

    @objc func captureRedirect(_ call: CAPPluginCall) {
        guard let customerId = LEANPlugin.normalizedRequiredString(call, "customerId") else {
            call.reject("customerId is required")
            return
        }
        let sandbox = call.getBool("sandbox") ?? true
        let country = call.getString("country")
        let appToken = LEANPlugin.normalizedOptionalString(call, "appToken")
        let accessToken = LEANPlugin.normalizedOptionalString(call, "accessToken")
        let consentAttemptId = LEANPlugin.normalizedOptionalString(call, "consentAttemptId")
        let granularStatusCode = LEANPlugin.normalizedOptionalString(call, "granularStatusCode")
        let statusAdditionalInfo = LEANPlugin.normalizedOptionalString(call, "statusAdditionalInfo")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupIfNeeded(call: call, appToken: appToken, sandbox: sandbox, country: country) {
                guard let viewController = self.resolveViewController(call) else { return }
                let context: [String: Any] = [
                    "method": "captureRedirect",
                    "customer_id": customerId,
                    "sandbox": sandbox,
                    "country": country ?? "sa"
                ]
                Lean.manager.captureRedirect(
                    presentingViewController: viewController,
                    customerId: customerId,
                    customization: nil,
                    accessToken: accessToken,
                    consentAttemptId: consentAttemptId,
                    granularStatusCode: granularStatusCode,
                    statusAdditionalInfo: statusAdditionalInfo,
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
// swiftlint:enable file_length type_body_length
