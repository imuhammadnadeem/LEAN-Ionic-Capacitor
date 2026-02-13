package com.codecraft_studio.lean

import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LEANPluginMethodExposureTest {

    @Test
    fun pluginAnnotationName_isLean() {
        val annotation = LEANPlugin::class.java.getAnnotation(CapacitorPlugin::class.java)
        assertNotNull(annotation)
        assertEquals("Lean", annotation?.name)
    }

    @Test
    fun exposesAllLeanFlows_asPluginMethods() {
        val exposedMethods = LEANPlugin::class.java.declaredMethods
            .filter { it.getAnnotation(PluginMethod::class.java) != null }
            .map { it.name }
            .toSet()

        val expectedMethods = setOf(
            "link",
            "connect",
            "reconnect",
            "createPaymentSource",
            "updatePaymentSource",
            "pay",
            "verifyAddress",
            "authorizeConsent",
            "checkout",
            "manageConsents",
            "captureRedirect",
        )

        assertTrue(
            "Missing plugin methods. expected=$expectedMethods actual=$exposedMethods",
            exposedMethods.containsAll(expectedMethods),
        )
    }
}
