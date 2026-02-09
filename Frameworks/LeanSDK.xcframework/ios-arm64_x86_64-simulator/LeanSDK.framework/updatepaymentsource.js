function postResponse(status) {
    status.method = "UPDATE_PAYMENT_SOURCE"
    if (status.bank && status.bank.bank_identifier) {
        status.bankId = status.bank.bank_identifier
        status.isSupported = status.bank.is_supported
    }
    if (status.status !== "ERROR" && status.status !== "CANCELLED") {
        window.webkit.messageHandlers.handleUpdatePaymentSourceSuccess.postMessage(status);
    } else {
        window.webkit.messageHandlers.handleUpdatePaymentSourceFailure.postMessage(status);
    }
}

try {
  Lean.updatePaymentSource({
      app_token: "${APP_TOKEN}",
      customer_id: "${CUSTOMER_ID}",
      payment_source_id: "${PAYMENT_SOURCE_ID}",
      payment_destination_id: "${PAYMENT_DESTINATION_ID}",
      ${CUSTOMIZATION}
      ${LANGUAGE}
      sandbox: "${SANDBOX}",
      callback: postResponse
  })
} catch (e) {
    window.webkit.messageHandlers.handleUpdatePaymentSourceFailure.postMessage({method: "UPDATE_PAYMENT_SOURCE", status: "ERROR", message: "Lean not initialized"});
}
