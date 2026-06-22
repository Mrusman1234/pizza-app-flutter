const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { setGlobalOptions, onInit } = require("firebase-functions/v2");
const admin = require("firebase-admin");

// ── DEFERRED INITIALIZATION ──────────────────────────────────────────
// Use onInit to prevent initialization logic from running during
// the deployment discovery process, avoiding timeouts.
onInit(() => {
    if (admin.apps.length === 0) {
        admin.initializeApp();
    }
});

// Set global region to asia-south1
setGlobalOptions({ region: "asia-south1" });

// Define Secrets (Must stay in global scope for metadata analysis)
const stripeSecret = defineSecret("STRIPE_SECRET");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
const jcMerchantId = defineSecret("JAZZCASH_MERCHANT_ID");
const jcPassword = defineSecret("JAZZCASH_PASSWORD");
const jcSalt = defineSecret("JAZZCASH_INTEGRITY_SALT");

/**
 * Helper to finalize order and move from order_requests to orders.
 */
async function finalizeCheckout(checkoutId, paymentId, paymentMethod, status = 'Paid') {
    const db = admin.firestore();
    const requestsSnap = await db.collection('order_requests')
        .where('parentCheckoutId', '==', checkoutId)
        .get();

    if (requestsSnap.empty) return;

    const batch = db.batch();
    for (const doc of requestsSnap.docs) {
        const data = doc.data();
        const subtotal = data.subtotal || 0;
        const tax = data.tax || 0;
        const deliveryFee = data.deliveryFee || 0;
        const discountAmount = data.discountAmount || 0;
        const totalAmount = data.totalAmount || (subtotal - discountAmount + tax + deliveryFee);

        batch.set(db.collection('orders').doc(doc.id), {
            ...data,
            subtotal,
            tax,
            deliveryFee,
            discountAmount,
            totalAmount,
            status: status === 'Paid' ? 'Pending' : 'Cancelled',
            paymentStatus: status,
            paymentMethod,
            paymentId,
            isVerified: status === 'Paid',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        batch.delete(doc.ref);
    }
    await batch.commit();
}

/**
 * Stripe: Create Payment Intent
 */
exports.createStripePayment = onCall({ secrets: [stripeSecret], enforceAppCheck: true }, async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');
    const { amount, checkoutId, email } = request.data;
    const stripe = require('stripe')(stripeSecret.value());

    try {
        let customer;
        const customers = await stripe.customers.list({ email, limit: 1 });
        customer = customers.data.length > 0 ? customers.data[0] : await stripe.customers.create({ email });

        const ephemeralKey = await stripe.ephemeralKeys.create({ customer: customer.id }, { apiVersion: '2022-11-15' });
        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(amount * 100),
            currency: 'pkr',
            customer: customer.id,
            metadata: { userId: request.auth.uid, checkoutId },
            automatic_payment_methods: { enabled: true }
        });

        return { clientSecret: paymentIntent.client_secret, ephemeralKey: ephemeralKey.secret, customer: customer.id };
    } catch (error) {
        throw new HttpsError('internal', error.message);
    }
});

/**
 * Stripe: Webhook Handler
 */
exports.stripeWebhook = onRequest({ secrets: [stripeWebhookSecret, stripeSecret] }, async (req, res) => {
    const stripe = require('stripe')(stripeSecret.value());
    const sig = req.headers['stripe-signature'];
    let event;
    try {
        event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeWebhookSecret.value());
    } catch (err) {
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }
    const paymentIntent = event.data.object;
    const checkoutId = paymentIntent.metadata.checkoutId;
    if (event.type === 'payment_intent.succeeded') {
        await finalizeCheckout(checkoutId, paymentIntent.id, 'Card', 'Paid');
    }
    res.json({ received: true });
});

/**
 * JazzCash: Initiate Payment
 */
exports.initiateJazzCashPayment = onCall({ secrets: [jcMerchantId, jcPassword, jcSalt], enforceAppCheck: true }, async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');
    const crypto = require("crypto");
    const { amount, checkoutId } = request.data;
    const projectId = process.env.GCLOUD_PROJECT || admin.app().options.projectId;
    const returnUrl = `https://asia-south1-${projectId}.cloudfunctions.net/jazzcashCallback`;
    const dateTime = new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 14);
    const postData = {
        "pp_Version": "1.1", "pp_TxnType": "MWALLET", "pp_Language": "EN",
        "pp_MerchantID": jcMerchantId.value(), "pp_Password": jcPassword.value(),
        "pp_TxnRefNo": 'T' + dateTime, "pp_Amount": Math.round(amount * 100).toString(),
        "pp_TxnCurrency": "PKR", "pp_TxnDateTime": dateTime, "pp_BillReference": checkoutId,
        "pp_Description": "Pizza Hub Order", "pp_ReturnURL": returnUrl, "ppmpf_1": request.auth.uid,
        "pp_TxnExpiryDateTime": new Date(Date.now() + 3600000).toISOString().replace(/[-:T.Z]/g, '').slice(0, 14),
    };
    const saltValue = jcSalt.value();
    const sortedKeys = Object.keys(postData).sort();
    let hashString = saltValue;
    for (const key of sortedKeys) {
        if (postData[key] !== undefined && postData[key] !== "") hashString += '&' + postData[key];
    }
    postData.pp_SecureHash = crypto.createHash('sha256').update(hashString).digest('hex').toUpperCase();
    const paymentUrl = "https://sandbox.jazzcash.com.pk/CustomerPortal/transaction/Checkout";
    const html = `<html><body onload="document.forms[0].submit()"><form method="post" action="${paymentUrl}">${Object.entries(postData).map(([k, v]) => `<input type="hidden" name="${k}" value="${v}">`).join('')}</form></body></html>`;
    return { html };
});

/**
 * JazzCash: Callback Handler
 */
exports.jazzcashCallback = onRequest({ secrets: [jcSalt] }, async (req, res) => {
    const crypto = require("crypto");
    const data = req.body;
    const saltValue = jcSalt.value();
    const sortedKeys = Object.keys(data).sort();
    let hashString = saltValue;
    for (const key of sortedKeys) {
        if (data[key] !== undefined && data[key] !== "" && key !== "pp_SecureHash") hashString += '&' + data[key];
    }
    if (data.pp_SecureHash !== crypto.createHash('sha256').update(hashString).digest('hex').toUpperCase()) {
        return res.status(400).send("Invalid Hash");
    }
    if (data.pp_ResponseCode === "000") {
        await finalizeCheckout(data.pp_BillReference, data.pp_TxnRefNo, 'JazzCash', 'Paid');
        res.redirect('https://pizzahub-admin.web.app/#/order-success?id=' + data.pp_BillReference);
    } else {
        res.redirect('https://pizzahub-admin.web.app/#/payment-failed');
    }
});

/**
 * Firestore Trigger: Finalize COD orders
 */
exports.finalizeOrder = onDocumentCreated('order_requests/{requestId}', async (event) => {
    const data = event.data.data();
    if (data.paymentMethod !== 'Cash on Delivery') return null;
    const subtotal = data.subtotal || 0;
    const tax = data.tax || 0;
    const deliveryFee = data.deliveryFee || 0;
    const discountAmount = data.discountAmount || 0;
    await admin.firestore().collection('orders').doc(event.params.requestId).set({
        ...data, subtotal, tax, deliveryFee, discountAmount,
        totalAmount: (subtotal - discountAmount + tax + deliveryFee),
        status: 'Pending', paymentStatus: 'Pending', isVerified: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return event.data.ref.delete();
});

/**
 * Scheduled: Cancel stale orders
 */
exports.cancelStaleOrders = onSchedule('every 5 minutes', async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - 20 * 60 * 1000);
    const staleOrders = await admin.firestore().collection('orders').where('status', '==', 'Pending').where('createdAt', '<', cutoff).get();
    if (staleOrders.empty) return;
    const batch = admin.firestore().batch();
    staleOrders.forEach(doc => batch.update(doc.ref, { status: 'Cancelled', cancelReason: 'Timeout' }));
    await batch.commit();
});

/**
 * Push Notification Triggers
 */
exports.onOrderStatusUpdate = onDocumentUpdated('orders/{orderId}', async (event) => {
    const newData = event.data.after.data();
    if (newData.status === event.data.before.data().status) return null;
    const userSnap = await admin.firestore().collection('users').doc(newData.userId).get();
    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken) return null;
    return admin.messaging().send({
        notification: { title: 'Order Update', body: `Your order is now: ${newData.status}` },
        data: { orderId: event.params.orderId, type: 'order_status' },
        token: fcmToken
    });
});

/**
 * Update Restaurant Average Rating
 */
exports.updateRestaurantRating = onDocumentUpdated('restaurants/{restaurantId}', async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    if (newData.totalRatingSum === oldData.totalRatingSum && newData.totalRatingCount === oldData.totalRatingCount) return null;
    if (!newData.totalRatingCount) return null;
    const rating = (Math.round((newData.totalRatingSum / newData.totalRatingCount) * 10) / 10).toString();
    if (newData.rating === rating) return null;
    return event.data.after.ref.update({ rating });
});
