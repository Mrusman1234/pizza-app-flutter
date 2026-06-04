# Production Backend Logic (Firebase Cloud Functions)

To make this app fully operational, you must deploy the following Firebase Cloud Functions. These handle security, finances, and automation that cannot be trusted to the Flutter app.

## 1. Automated Order Expiry
This function runs every 5 minutes and cancels orders that haven't been accepted by a rider for 20 minutes.

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.cancelStaleOrders = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const staleTime = 20 * 60 * 1000; // 20 minutes in ms
    
    const staleOrders = await admin.firestore().collection('orders')
        .where('status', '==', 'Pending')
        .where('createdAt', '<', new Date(now.toDate().getTime() - staleTime))
        .get();

    const batch = admin.firestore().batch();
    staleOrders.forEach(doc => {
        batch.update(doc.ref, { 
            status: 'Cancelled', 
            cancelReason: 'No rider accepted the order in time' 
        });
    });

    return batch.commit();
});
```

## 2. Push Notification Triggers
Automatically notify users when order status changes.

```javascript
exports.onOrderStatusUpdate = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        if (newData.status === oldData.status) return null;

        const userId = newData.userId;
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        const fcmToken = userDoc.data().fcmToken;

        if (!fcmToken) return null;

        let message = {
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

## 3. Order Finalization (Security)
Converts `order_requests` (Drafts) into real `orders` after verifying prices.

```javascript
exports.finalizeOrder = functions.firestore
    .document('order_requests/{requestId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const db = admin.firestore();

        // 1. Fetch REAL prices from Firestore
        let subtotal = 0;
        for (const item of data.items) {
            const product = await db.doc(`restaurants/${data.restaurantId}/menu/${item.pizzaId}`).get();
            subtotal += product.data().price * item.quantity;
        }

        // 2. Fetch dynamic config (Taxes & Fees)
        const configDoc = await db.doc('app_config/settings').get();
        const config = configDoc.data();
        const baseDeliveryFee = config.baseDeliveryFee || 50.0;
        const taxRate = config.taxRate || 0.05;

        // 3. Verified Calculation
        const tax = subtotal * taxRate;
        const deliveryFee = baseDeliveryFee;
        const totalAmount = subtotal + tax + deliveryFee;

        // 4. Create Final Order
        await db.collection('orders').add({
            ...data,
            subtotal,
            totalAmount,
            tax,
            deliveryFee,
            status: 'Pending',
            isVerified: true
        });

        // 5. Delete the request
        return snap.ref.delete();
    });
```
