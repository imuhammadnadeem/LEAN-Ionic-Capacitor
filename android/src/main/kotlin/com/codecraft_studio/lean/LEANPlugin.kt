package com.codecraft_studio.lean

import android.app.Activity
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import org.json.JSONArray
import java.lang.reflect.Proxy

/**
 * Capacitor plugin bridging to Lean Link Android SDK via reflection.
 * The host app must add: implementation "me.leantech:link-sdk-android:3.0.2"
 * and JitPack: maven { url 'https://jitpack.io' }
 */
@CapacitorPlugin(name = "Lean")
class LEANPlugin : Plugin() {

    private var leanInstance: Any? = null
    private var cachedAppToken: String? = null
    private var cachedSandbox: Boolean? = null

    private val leanClassNames = listOf("me.leantech.lean.Lean", "me.leantech.Lean")

    private fun findLeanClass(): Class<*>? {
        for (name in leanClassNames) {
            try {
                return Class.forName(name)
            } catch (_: ClassNotFoundException) { }
        }
        return null
    }

    private fun getLean(appToken: String?, sandbox: Boolean): Any? {
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
            builder = setCountry.invoke(builder, "ae")
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

    @PluginMethod
    fun connect(call: PluginCall) {
        val customerId = call.getString("customerId")
        val appToken = call.getString("appToken")
        val sandbox = call.getBoolean("sandbox") ?: true
        val permissionsArr = call.getArray("permissions") ?: JSONArray()
        val bankIdentifier = call.getString("bankIdentifier")
        val paymentDestinationId = call.getString("paymentDestinationId")
        val successRedirectUrl = call.getString("successRedirectUrl")
        val failRedirectUrl = call.getString("failRedirectUrl")

        if (customerId.isNullOrBlank()) {
            call.reject("customerId is required")
            return
        }

        val leanClass = findLeanClass()
        if (leanClass == null) {
            call.reject(
                "Lean SDK not found. Add to your app's build.gradle: implementation \"me.leantech:link-sdk-android:3.0.2\" " +
                "and maven { url 'https://jitpack.io' } in repositories."
            )
            return
        }

        val lean = getLean(appToken, sandbox)
        if (lean == null) {
            call.reject("appToken is required for Android. Pass appToken in connect options.")
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
                call.resolve(responseToJS(args[0]))
            }
            null
        }

        activity.runOnUiThread {
            try {
                val connectMethod = lean.javaClass.methods.find { m ->
                    m.name == "connect" && m.parameterCount >= 5
                } ?: run {
                    call.reject("Lean connect method not found")
                    return@runOnUiThread
                }
                // Lean.connect(activity, customerId, bankIdentifier, paymentDestinationId, permissions,
                //   customization, accessTo, accessFrom, failRedirectUrl, successRedirectUrl, accountType,
                //   endUserId, accessToken, showConsentExplanation, destinationAlias, destinationAvatar,
                //   customerMetadata, leanListener)
                val args = arrayOf(
                    activity,
                    customerId,
                    bankIdentifier,
                    paymentDestinationId,
                    ArrayList(permissions),
                    null, null, null,
                    failRedirectUrl,
                    successRedirectUrl,
                    null, null, null, null, null, null, null,
                    proxyListener
                )
                val paramCount = connectMethod.parameterTypes.size
                val toPass = if (args.size == paramCount) args else args.take(paramCount).toTypedArray()
                connectMethod.invoke(lean, *toPass)
            } catch (e: Exception) {
                call.reject("Lean connect failed: ${e.message}", e)
            }
        }
    }
}
