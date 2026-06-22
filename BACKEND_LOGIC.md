# Production Backend Logic (Firebase Cloud Functions)

To make this app fully operational, you must deploy the following Firebase Cloud Functions. These handle security, finances, and automation that cannot be trusted to the Flutter app.

**Initialization:**
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const env = require('./config/env');
const stripe = require('stripe')(env.STRIPE_SECRET);
admin.initializeApp();
```

## 1. Payment Flow (Stripe Integration)

### A. Create Stripe Payment
Called by the Flutter app via `HttpsCallable` to initiate a Stripe transaction.
- **Input:** `amount`, `requestId`
- **Output:** `clientSecret`

### B. Create JazzCash Payment Request
Called by the Flutter app to get a redirect URL for JazzCash.
- **Input:** `amount`, `requestId`
- **Output:** `redirectUrl`

### C. JazzCash Webhook / Callback
Handles the response from JazzCash after payment.
- **Trigger:** HTTP POST to `/verifyJazzCashPayment`
- **Logic:**
  1. Checks `pp_ResponseCode` (000 = Success).
  2. Records payment in `payments` collection.
  3. Moves `order_requests` to `orders` with `status: "Paid"`.

### D. Stripe Webhook
Handles the asynchronous payment confirmation from Stripe.
- **Trigger:** HTTP POST to `/stripeWebhook`
- **Logic:**
  1. Verifies the Stripe signature.
  2. On `payment_intent.succeeded`, fetches the corresponding `order_requests` document.
  3. Moves the data to the `orders` collection with `status: "Paid"`.
  4. Deletes the original `order_requests` document.

## 2. Automated Order Expiry
This function runs every 5 minutes and cancels orders that haven't been accepted by a rider for 20 minutes. Uses safe Firestore Timestamp comparisons.

```javascript
exports.cancelStaleOrders = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const cutoff = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - 20 * 60 * 1000 // 20 minutes in ms
    );
    
    const staleOrders = await admin.firestore().collection('orders')
        .where('status', '==', 'Pending')
        .where('createdAt', '<', cutoff)
        .get();

    if (staleOrders.empty) return null;

    const batch = admin.firestore().batch();
    staleOrders.forEach(doc => {
        batch.update(doc.ref, { 
            status: 'Cancelled', 
            cancelReason: 'Auto-cancelled (timeout)' 
        });
    });

    return batch.commit();
});
```

## 3. Push Notification Triggers
Automatically notify users when order status changes. Includes null safety for user documents and tokens.

```javascript
exports.onOrderStatusUpdate = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        // Avoid unnecessary triggers
        if (newData.status === oldData.status) return null;

        const userSnap = await admin.firestore()
            .collection('users')
            .doc(newData.userId)
            .get();

        if (!userSnap.exists) return null;

        const fcmToken = userSnap.data().fcmToken;
        if (!fcmToken) return null;

        const message = {
            notification: {
                title: 'Order Update',
                body: `Your order is now: ${newData.status}`,
            },
            data: {
                orderId: context.params.orderId,
                type: 'order_status'
            },
            token: fcmToken
        };

        return admin.messaging().send(message);
    });
```

## 4. Order Finalization (Security & COD)
Converts `order_requests` (Drafts) into real `orders` after verifying prices for Cash on Delivery (COD) orders.
**Key Improvements:** Idempotency (uses `requestId` as document ID), server-side timestamps, and verified price checks.
- **Note:** If `paymentMethod == "Stripe"`, this function ignores the request and waits for the Webhook to finalize it.

```javascript
exports.finalizeOrder = functions.firestore
    .document('order_requests/{requestId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        if (data.paymentMethod === 'Stripe') return null; // Wait for webhook
        
        // ... (Price verification logic)
        
        await db.collection('orders').doc(requestId).set(orderData);
        return snap.ref.delete();
    });
```

---

### 🚀 Deployment & Config
1. **Set Environment Variables:**
   Create a `.env` file in the `functions` directory:
   ```env
   STRIPE_SECRET=sk_test_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   JAZZCASH_MERCHANT_ID=...
   JAZZCASH_PASSWORD=...
   JAZZCASH_INTEGERITY_SALT=...
   ```
   For production deployment using Firebase Secrets:
   ```bash
   firebase functions:secrets:set STRIPE_SECRET
   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
   firebase functions:secrets:set JAZZCASH_MERCHANT_ID
   firebase functions:secrets:set JAZZCASH_PASSWORD
   firebase functions:secrets:set JAZZCASH_INTEGERITY_SALT
   ```
2. **Deploy:**
   ```bash
   firebase deploy --only functions
   ```
3. **Webhook URLs:**
   - Stripe: `https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook`
   - JazzCash: `https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/verifyJazzCashPayment`
