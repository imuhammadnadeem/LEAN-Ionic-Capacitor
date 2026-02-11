import test from 'node:test';
import assert from 'node:assert/strict';
import { LeanWeb } from '../../dist/esm/web.js';

function setLeanMethod(methodName, handler) {
  globalThis.window = {
    Lean: {
      [methodName]: handler,
    },
  };
}

test('connect throws when Lean SDK is missing', async () => {
  globalThis.window = {};
  const web = new LeanWeb();
  await assert.rejects(
    () =>
      web.connect({
        customerId: 'cust_1',
        permissions: ['accounts'],
      }),
    /Lean Web SDK not loaded/,
  );
});

test('link maps options to Lean Web payload', async () => {
  let captured;
  setLeanMethod('link', (params) => {
    captured = params;
    params.callback({ status: 'SUCCESS' });
  });

  const web = new LeanWeb();
  const result = await web.link({
    customerId: 'cust_1',
    permissions: ['identity', 'accounts'],
    sandbox: false,
    appToken: 'app_123',
    accessToken: 'access_123',
    bankIdentifier: 'LEANMB1',
    successRedirectUrl: 'app://success',
    failRedirectUrl: 'app://fail',
  });

  assert.equal(result.status, 'SUCCESS');
  assert.equal(captured.customer_id, 'cust_1');
  assert.deepEqual(captured.permissions, ['identity', 'accounts']);
  assert.equal(captured.sandbox, 'false');
  assert.equal(captured.app_token, 'app_123');
  assert.equal(captured.access_token, 'access_123');
  assert.equal(captured.bank_identifier, 'LEANMB1');
  assert.equal(captured.success_redirect_url, 'app://success');
  assert.equal(captured.fail_redirect_url, 'app://fail');
  assert.equal(typeof captured.callback, 'function');
});

test('updatePaymentSource validates required fields', async () => {
  setLeanMethod('updatePaymentSource', (params) => {
    params.callback({ status: 'SUCCESS' });
  });

  const web = new LeanWeb();
  await assert.rejects(
    () =>
      web.updatePaymentSource({
        customerId: 'cust_1',
        paymentSourceId: '',
        paymentDestinationId: 'dest_1',
      }),
    /paymentSourceId is required/,
  );
});

test('pay maps payment payload', async () => {
  let captured;
  setLeanMethod('pay', (params) => {
    captured = params;
    params.callback({ status: 'SUCCESS' });
  });

  const web = new LeanWeb();
  const result = await web.pay({
    paymentIntentId: 'pi_1',
    accountId: 'acc_1',
  });

  assert.equal(result.status, 'SUCCESS');
  assert.equal(captured.payment_intent_id, 'pi_1');
  assert.equal(captured.account_id, 'acc_1');
  assert.equal(captured.sandbox, 'true');
});
