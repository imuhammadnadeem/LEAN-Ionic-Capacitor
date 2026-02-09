import { Lean } from 'lean-ionic-capacitor';

window.testConnect = async () => {
  const customerId = document.getElementById('customerId').value;
  const resultEl = document.getElementById('result');
  try {
    const result = await Lean.connect({
      customerId: customerId || 'test-customer-123',
      permissions: ['accounts', 'transactions'],
      sandbox: true,
      // On Web, pass appToken (and optionally accessToken) for the SDK to work
      // appToken: 'YOUR_APP_TOKEN',
      // accessToken: 'YOUR_CUSTOMER_SCOPED_TOKEN',
    });
    resultEl.textContent = JSON.stringify(result, null, 2);
  } catch (e) {
    resultEl.textContent = 'Error: ' + (e && e.message ? e.message : String(e));
  }
};
