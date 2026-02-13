package com.codecraft_studio.lean

import android.app.Activity
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import org.json.JSONArray
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method
import java.lang.reflect.Proxy

/**
 * Capacitor plugin bridging to Lean Link Android SDK via reflection.
 * The host app must add: implementation "me.leantech:link-sdk-android:3.0.8"
 * and JitPack: maven { url 'https://jitpack.io' }
 */
@CapacitorPlugin(name = "Lean")
class LEANPlugin : Plugin() {

    private var leanInstance: Any? = null
    private var cachedAppToken: String? = null
    private var cachedSandbox: Boolean? = null

    // Support current SDK namespace first, while keeping backward compatibility.
    private val leanClassNames = listOf(
        "me.leantech.link.android.Lean",
        "me.leantech.lean.Lean",
        "me.leantech.Lean"
    )

    private fun findLeanClass(): Class<*>? {
        for (name in leanClassNames) {
            try {
                return Class.forName(name)
            } catch (_: ClassNotFoundException) { }
        }
        return null
    }

    private fun getLean(appToken: String?, sandbox: Boolean, country: String?): Any? {
        if (leanInstance != null && appToken != null && appToken == cachedAppToken && sandbox == cachedSandbox) {
            return leanInstance
        }
        if (appToken.isNullOrBlank()) return null
        val leanClass = findLeanClass()
            ?: return null
        try {
            val builderClass = leanClass.declaredClasses.find { it.simpleName == "Builder" }
                ?: return null
            val builderCtor = builderClass.getConstructor()
            val buildMethod = builderClass.getMethod("build")
            val setAppToken = builderClass.getMethod("setAppToken", String::class.java)
            val setVersion = builderClass.getMethod("setVersion", String::class.java)
            val setCountry = builderClass.getMethod("setCountry", String::class.java)
            val setLanguage = builderClass.getMethod("setLanguage", String::class.java)
            val setSandboxMode = builderClass.getMethod("setSandboxMode")

            var builder = builderCtor.newInstance()
            builder = setAppToken.invoke(builder, appToken)
            builder = setVersion.invoke(builder, "latest")
            val resolvedCountry = if (country.isNullOrBlank()) "sa" else country.lowercase()
            builder = setCountry.invoke(builder, resolvedCountry)
            builder = setLanguage.invoke(builder, "en")
            if (sandbox) builder = setSandboxMode.invoke(builder)
            leanInstance = buildMethod.invoke(builder)
            cachedAppToken = appToken
            cachedSandbox = sandbox
            return leanInstance
        } catch (e: Exception) {
            return null
        }
    }

    private fun mapPermissions(leanClass: Class<*>, arr: JSONArray?): List<Any> {
        val list = mutableListOf<Any>()
        arr ?: return list
        val permissionsClass = leanClass.declaredClasses.find { it.simpleName == "UserPermissions" }
            ?: return list
        val identity = permissionsClass.enumConstants?.find { it.toString() == "IDENTITY" }
        val accounts = permissionsClass.enumConstants?.find { it.toString() == "ACCOUNTS" }
        val transactions = permissionsClass.enumConstants?.find { it.toString() == "TRANSACTIONS" }
        val balance = permissionsClass.enumConstants?.find { it.toString() == "BALANCE" }
        val payments = permissionsClass.enumConstants?.find { it.toString() == "PAYMENTS" }
        for (i in 0 until arr.length()) {
            when (arr.optString(i, "").lowercase()) {
                "identity" -> if (identity != null) list.add(identity)
                "accounts" -> if (accounts != null) list.add(accounts)
                "transactions" -> if (transactions != null) list.add(transactions)
                "balance" -> if (balance != null) list.add(balance)
                "payments" -> if (payments != null) list.add(payments)
                else -> {}
            }
        }
        return list
    }

    private fun responseToJS(response: Any?): JSObject {
        val o = JSObject()
        if (response == null) return o
        try {
            val status = response.javaClass.getMethod("getStatus").invoke(response)?.toString() ?: "ERROR"
            val message = response.javaClass.getMethod("getMessage").invoke(response)?.toString()
            val lastApiResponse = response.javaClass.getMethod("getLastApiResponse").invoke(response)?.toString()
            val exitPoint = response.javaClass.getMethod("getExitPoint").invoke(response)?.toString()
            val secondaryStatus = response.javaClass.getMethod("getSecondaryStatus").invoke(response)?.toString()
            o.put("status", status)
            o.put("message", message)
            o.put("last_api_response", lastApiResponse)
            o.put("exit_point", exitPoint)
            o.put("secondary_status", secondaryStatus)
            try {
                val bank = response.javaClass.getMethod("getBank").invoke(response)
                if (bank != null) {
                    val bankObj = JSObject()
                    val getBankId = bank.javaClass.methods.find { it.name == "getBankIdentifier" }
                    val getSupported = bank.javaClass.methods.find { it.name == "getIsSupported" || it.name == "isSupported" }
                    bankObj.put("bank_identifier", getBankId?.invoke(bank)?.toString())
                    bankObj.put("is_supported", getSupported?.invoke(bank) as? Boolean ?: true)
                    o.put("bank", bankObj)
                }
            } catch (_: Exception) { }
        } catch (_: Exception) {
            o.put("status", "ERROR")
            o.put("message", "Failed to serialize response")
        }
        return o
    }

    private fun invokeLeanMethod(
        call: PluginCall,
        methodName: String,
        appToken: String?,
        sandbox: Boolean,
        country: String?,
        permissionsArr: JSONArray? = null,
        orderedStringArgs: List<String?> = emptyList(),
        orderedBooleanArgs: List<Boolean?> = emptyList()
    ) {
        val leanClass = findLeanClass()
        if (leanClass == null) {
            call.reject(
                "Lean SDK not found. In your app's Android project: (1) Add maven { url 'https://jitpack.io' } to repositories (e.g. in settings.gradle or root build.gradle). " +
                    "(2) In app/build.gradle dependencies add: implementation \"me.leantech:link-sdk-android:3.0.8\". " +
                    "(3) In app/proguard-rules.pro add keep rules for me.leantech.link.android.** (and optionally legacy me.leantech.lean.**) (see plugin HOST_APP_SETUP.md). " +
                    "Then run: npx cap sync android and do a clean rebuild."
            )
            return
        }

        val lean = getLean(appToken, sandbox, country)
        if (lean == null) {
            call.reject("appToken is required for Android. Pass appToken in ${methodName} options.")
            return
        }

        val activity: Activity? = getActivity()
        if (activity == null) {
            call.reject("Activity not available")
            return
        }

        val permissions = mapPermissions(leanClass, permissionsArr)
        val listenerInterface = leanClass.declaredClasses.find { it.simpleName == "Listener" }
            ?: run {
                call.reject("Lean SDK Listener not found")
                return
            }
        val responseClass = leanClass.declaredClasses.find { it.simpleName == "Response" }
            ?: run {
                call.reject("Lean SDK Response not found")
                return
            }
        val proxyListener = Proxy.newProxyInstance(
            listenerInterface.classLoader,
            arrayOf(listenerInterface)
        ) { _, method, args ->
            if (method.name == "onResponse" && args != null && args.isNotEmpty()) {
                if (!responseClass.isInstance(args[0])) {
                    call.reject("Lean SDK Response payload type mismatch")
                    return@newProxyInstance null
                }
                call.resolve(responseToJS(args[0]))
            }
            null
        }

        activity.runOnUiThread {
            try {
                val candidateMethods = lean.javaClass.methods.filter { m ->
                    m.name == methodName && m.parameterTypes.any { p -> listenerInterface.isAssignableFrom(p) }
                }
                val targetMethod = candidateMethods.maxByOrNull { it.parameterCount }
                    ?: run {
                        call.reject("Lean $methodName method not found")
                        return@runOnUiThread
                    }
                val args = buildArgsForMethod(
                    method = targetMethod,
                    activity = activity,
                    permissions = permissions,
                    orderedStringArgs = orderedStringArgs,
                    orderedBooleanArgs = orderedBooleanArgs,
                    listenerInterface = listenerInterface,
                    listener = proxyListener
                )
                targetMethod.invoke(lean, *args)
            } catch (e: InvocationTargetException) {
                val cause = e.cause
                val message = cause?.message ?: e.message ?: "unknown error"
                val ex = if (cause is Exception) cause else Exception(message, cause ?: e)
                call.reject("Lean $methodName failed: $message", ex)
            } catch (e: Exception) {
                call.reject("Lean $methodName failed: ${e.message ?: "unknown error"}", e)
            }
        }
    }

    private fun buildArgsForMethod(
        method: Method,
        activity: Activity,
        permissions: List<Any>,
        orderedStringArgs: List<String?>,
        orderedBooleanArgs: List<Boolean?>,
        listenerInterface: Class<*>,
        listener: Any
    ): Array<Any?> {
        val args = MutableList<Any?>(method.parameterCount) { null }
        var stringIndex = 0
        var boolIndex = 0

        for (i in method.parameterTypes.indices) {
            val type = method.parameterTypes[i]
            when {
                listenerInterface.isAssignableFrom(type) -> args[i] = listener
                Activity::class.java.isAssignableFrom(type) -> args[i] = activity
                java.util.List::class.java.isAssignableFrom(type) -> args[i] = ArrayList(permissions)
                type == java.lang.Boolean.TYPE || type == java.lang.Boolean::class.java -> {
                    args[i] = if (boolIndex < orderedBooleanArgs.size) orderedBooleanArgs[boolIndex++] else null
                }
                type == String::class.java -> {
                    args[i] = if (stringIndex < orderedStringArgs.size) orderedStringArgs[stringIndex++] else null
                }
                else -> args[i] = null
            }
        }

        if (!args.any { it === listener }) {
            args[method.parameterCount - 1] = listener
        }
        return args.toTypedArray()
    }

    @PluginMethod
    fun connect(call: PluginCall) {
        val customerId = call.getString("customerId")
        val appToken = call.getString("appToken")
        val sandbox = call.getBoolean("sandbox") ?: true
        val country = call.getString("country")
        val permissionsArr = call.getArray("permissions") ?: JSONArray()
        val bankIdentifier = call.getString("bankIdentifier")
        val paymentDestinationId = call.getString("paymentDestinationId")
        val successRedirectUrl = call.getString("successRedirectUrl")
        val failRedirectUrl = call.getString("failRedirectUrl")
        val accessToken = call.getString("accessToken")

        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "connect",
            appToken = appToken,
            sandbox = sandbox,
            country = country,
            permissionsArr = permissionsArr,
            orderedStringArgs = listOf(
                customerId,
                bankIdentifier,
                paymentDestinationId,
                failRedirectUrl,
                successRedirectUrl,
                call.getString("accountType"),
                call.getString("endUserId"),
                call.getString("accessFrom"),
                call.getString("accessTo"),
                accessToken,
                call.getString("destinationAlias"),
                call.getString("destinationAvatar"),
                call.getString("customerMetadata")
            ),
            orderedBooleanArgs = listOf(call.getBoolean("showConsentExplanation"))
        )
    }

    @PluginMethod
    fun link(call: PluginCall) {
        val customerId = call.getString("customerId")
        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "link",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            permissionsArr = call.getArray("permissions") ?: JSONArray(),
            orderedStringArgs = listOf(
                customerId,
                call.getString("bankIdentifier"),
                call.getString("failRedirectUrl"),
                call.getString("successRedirectUrl"),
                call.getString("accessToken"),
                call.getString("destinationAlias"),
                call.getString("destinationAvatar")
            )
        )
    }

    @PluginMethod
    fun reconnect(call: PluginCall) {
        val reconnectId = call.getString("reconnectId")
        if (reconnectId.isNullOrBlank()) {
            call.reject("reconnectId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "reconnect",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                reconnectId,
                call.getString("accessToken"),
                call.getString("destinationAlias"),
                call.getString("destinationAvatar")
            )
        )
    }

    @PluginMethod
    fun createPaymentSource(call: PluginCall) {
        val customerId = call.getString("customerId")
        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "createPaymentSource",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                customerId,
                call.getString("bankIdentifier"),
                call.getString("paymentDestinationId"),
                call.getString("failRedirectUrl"),
                call.getString("successRedirectUrl"),
                call.getString("accessToken"),
                call.getString("destinationAlias"),
                call.getString("destinationAvatar")
            )
        )
    }

    @PluginMethod
    fun updatePaymentSource(call: PluginCall) {
        val customerId = call.getString("customerId")
        val paymentSourceId = call.getString("paymentSourceId")
        val paymentDestinationId = call.getString("paymentDestinationId")
        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }
        if (paymentSourceId.isNullOrBlank()) {
            call.reject("paymentSourceId is required")
            return
        }
        if (paymentDestinationId.isNullOrBlank()) {
            call.reject("paymentDestinationId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "updatePaymentSource",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                customerId,
                paymentSourceId,
                paymentDestinationId,
                call.getString("endUserId"),
                call.getString("accessToken"),
                call.getString("entityId"),
                call.getString("destinationAlias"),
                call.getString("destinationAvatar")
            )
        )
    }

    @PluginMethod
    fun pay(call: PluginCall) {
        val paymentIntentId = call.getString("paymentIntentId")
        val bulkPaymentIntentId = call.getString("bulkPaymentIntentId")
        if (paymentIntentId.isNullOrBlank() && bulkPaymentIntentId.isNullOrBlank()) {
            call.reject("paymentIntentId or bulkPaymentIntentId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "pay",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                paymentIntentId,
                bulkPaymentIntentId,
                call.getString("accountId"),
                call.getString("bankIdentifier"),
                call.getString("endUserId"),
                call.getString("failRedirectUrl"),
                call.getString("successRedirectUrl"),
                call.getString("accessToken"),
                call.getString("destinationAlias"),
                call.getString("destinationAvatar")
            )
        )
    }

    @PluginMethod
    fun verifyAddress(call: PluginCall) {
        val customerId = call.getString("customerId")
        val customerName = call.getString("customerName")
        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }
        if (customerName.isNullOrBlank()) {
            call.reject("customerName is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "verifyAddress",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            permissionsArr = call.getArray("permissions") ?: JSONArray(),
            orderedStringArgs = listOf(
                customerId,
                customerName,
                call.getString("accessToken"),
                call.getString("destinationAlias"),
                call.getString("destinationAvatar")
            )
        )
    }

    @PluginMethod
    fun authorizeConsent(call: PluginCall) {
        val customerId = call.getString("customerId")
        val consentId = call.getString("consentId")
        val failRedirectUrl = call.getString("failRedirectUrl")
        val successRedirectUrl = call.getString("successRedirectUrl")
        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }
        if (consentId.isNullOrBlank()) {
            call.reject("consentId is required")
            return
        }
        if (failRedirectUrl.isNullOrBlank()) {
            call.reject("failRedirectUrl is required")
            return
        }
        if (successRedirectUrl.isNullOrBlank()) {
            call.reject("successRedirectUrl is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "authorizeConsent",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                customerId,
                consentId,
                failRedirectUrl,
                successRedirectUrl,
                call.getString("accessToken"),
                call.getString("destinationAlias"),
                call.getString("destinationAvatar")
            )
        )
    }

    @PluginMethod
    fun checkout(call: PluginCall) {
        val paymentIntentId = call.getString("paymentIntentId")
        if (paymentIntentId.isNullOrBlank()) {
            call.reject("paymentIntentId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "checkout",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                paymentIntentId,
                call.getString("customerName"),
                call.getString("bankIdentifier"),
                call.getString("accessToken"),
                call.getString("successRedirectUrl"),
                call.getString("failRedirectUrl")
            )
        )
    }

    @PluginMethod
    fun manageConsents(call: PluginCall) {
        val customerId = call.getString("customerId")
        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "manageConsents",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                customerId,
                call.getString("accessToken")
            )
        )
    }

    @PluginMethod
    fun captureRedirect(call: PluginCall) {
        val customerId = call.getString("customerId")
        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }

        invokeLeanMethod(
            call = call,
            methodName = "captureRedirect",
            appToken = call.getString("appToken"),
            sandbox = call.getBoolean("sandbox") ?: true,
            country = call.getString("country"),
            orderedStringArgs = listOf(
                customerId,
                call.getString("accessToken"),
                call.getString("consentAttemptId"),
                call.getString("granularStatusCode"),
                call.getString("statusAdditionalInfo")
            )
        )
    }
}
