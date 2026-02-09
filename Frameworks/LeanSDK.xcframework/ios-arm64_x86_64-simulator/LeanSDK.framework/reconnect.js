function postResponse(status) {
    status.method = "RECONNECT"
    if (status.bank && status.bank.bank_identifier) {
        status.bankId = status.bank.bank_identifier
        status.isSupported = status.bank.is_supported
    }
    if (status.status !== "ERROR" && status.status !== "CANCELLED") {
        window.webkit.messageHandlers.handleReconnectSuccess.postMessage(status);
    } else {
        window.webkit.messageHandlers.handleReconnectFailure.postMessage(status);
    }
}

try {
  Lean.reconnect({
      app_token: "${APP_TOKEN}",
      reconnect_id: "${RECONNECT_ID}",
      customer_id: "${CUSTOMER_ID}",
      ${CUSTOMIZATION}
      ${LANGUAGE}
      sandbox: "${SANDBOX}",
      callback: postResponse
  })
} catch (e) {
    window.webkit.messageHandlers.handleReconnectFailure.postMessage({message: "Lean not initialized"});
}
