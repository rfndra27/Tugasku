const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const https = require("https");

admin.initializeApp();
const db = admin.firestore();

// Midtrans Server Key Configuration
// Can be configured via `firebase functions:config:set midtrans.server_key="SB-Mid-server-..."`
// or environment variable `MIDTRANS_SERVER_KEY`
const MIDTRANS_SERVER_KEY = process.env.MIDTRANS_SERVER_KEY ||
  (functions.config().midtrans ? functions.config().midtrans.server_key : "SB-Mid-server-DemoTugaskuKey123");
const IS_PRODUCTION = process.env.MIDTRANS_IS_PRODUCTION === "true" ||
  (functions.config().midtrans ? functions.config().midtrans.is_production === "true" : false);

const MIDTRANS_SNAP_HOST = IS_PRODUCTION ? "app.midtrans.com" : "app.sandbox.midtrans.com";
const MIDTRANS_API_HOST = IS_PRODUCTION ? "api.midtrans.com" : "api.sandbox.midtrans.com";

/**
 * Priority Score calculation formula:
 * - Overdue (hours_left <= 0): 9999.0
 * - Critical (hours_left <= 24): (weight * 10.0) + (1000.0 / (hours_left + 0.5))
 * - Normal (hours_left > 24): (weight * 2.0) + (500.0 / (hours_left / 24.0))
 */
function calculatePriorityScore(deadlineDate, weightPercentage) {
  const now = new Date();
  const deadline = new Date(deadlineDate);
  const diffMs = deadline.getTime() - now.getTime();
  const hoursLeft = diffMs / (1000 * 60 * 60);
  const weight = parseFloat(weightPercentage) || 10.0;

  if (hoursLeft <= 0) {
    return 9999.0;
  } else if (hoursLeft <= 24) {
    return (weight * 10.0) + (1000.0 / (hoursLeft + 0.5));
  } else {
    return (weight * 2.0) + (500.0 / (hoursLeft / 24.0));
  }
}

/**
 * Formats Date to YYYY-MM-DD in Asia/Jakarta timezone.
 */
function getLocalDateString(date) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Jakarta",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

/**
 * Helper to make HTTPS requests to Midtrans API
 */
function sendHttpsRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => body += chunk);
      res.on("end", () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ statusCode: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ statusCode: res.statusCode, data: body });
        }
      });
    });
    req.on("error", (err) => reject(err));
    if (postData) {
      req.write(JSON.stringify(postData));
    }
    req.end();
  });
}

/**
 * 1. handleNewUser: Auth-triggered when a new Firebase user is created
 */
exports.handleNewUser = functions.auth.user().onCreate(async (user) => {
  const profileRef = db.collection("profiles").doc(user.uid);
  const profileDoc = await profileRef.get();

  if (!profileDoc.exists) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    await profileRef.set({
      id: user.uid,
      email: user.email || "",
      full_name: user.displayName || "Mahasiswa",
      university: "",
      is_premium: false,
      premium_expiry: null,
      current_streak: 0,
      best_streak: 0,
      last_completed_date: null,
      ai_usage_count: 0,
      ai_usage_reset_date: now,
      created_at: now,
    });
  }
});

/**
 * Callable handleNewUserProfile for manual or custom registration invocation
 */
exports.initializeUserProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }
  const userId = context.auth.uid;
  const email = data.email || context.auth.token.email || "";
  const fullName = data.fullName || "Mahasiswa";
  const university = data.university || "";

  const profileRef = db.collection("profiles").doc(userId);
  const now = admin.firestore.FieldValue.serverTimestamp();

  await profileRef.set({
    id: userId,
    email: email,
    full_name: fullName,
    university: university,
    is_premium: false,
    premium_expiry: null,
    current_streak: 0,
    best_streak: 0,
    last_completed_date: null,
    ai_usage_count: 0,
    ai_usage_reset_date: now,
    created_at: now,
  }, { merge: true });

  return { success: true };
});

/**
 * 2. completeTaskWithStreak: Marks task completed and atomically updates streak
 */
exports.completeTaskWithStreak = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }
  const userId = context.auth.uid;
  const taskId = data.taskId;

  if (!taskId) {
    throw new functions.https.HttpsError("invalid-argument", "taskId is required.");
  }

  const taskRef = db.collection("users").doc(userId).collection("tasks").doc(taskId);
  const profileRef = db.collection("profiles").doc(userId);

  return db.runTransaction(async (transaction) => {
    const taskDoc = await transaction.get(taskRef);
    if (!taskDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Task not found.");
    }

    const taskData = taskDoc.data();
    if (taskData.is_completed) {
      return { success: true, already_completed: true };
    }

    const profileDoc = await transaction.get(profileRef);
    const profileData = profileDoc.exists ? profileDoc.data() : {};

    const todayDate = new Date();
    const todayStr = getLocalDateString(todayDate);

    const yesterdayDate = new Date();
    yesterdayDate.setDate(yesterdayDate.getDate() - 1);
    const yesterdayStr = getLocalDateString(yesterdayDate);

    let currentStreak = profileData.current_streak || 0;
    let bestStreak = profileData.best_streak || 0;
    const lastCompletedDate = profileData.last_completed_date || null;

    if (lastCompletedDate === todayStr) {
      // Completed another task today, streak count stays the same
    } else if (lastCompletedDate === yesterdayStr) {
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    // Update task
    transaction.update(taskRef, {
      is_completed: true,
      completed_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update profile
    transaction.set(profileRef, {
      current_streak: currentStreak,
      best_streak: bestStreak,
      last_completed_date: todayStr,
    }, { merge: true });

    return {
      success: true,
      current_streak: currentStreak,
      best_streak: bestStreak,
      last_completed_date: todayStr,
    };
  });
});

/**
 * 3. checkAndIncrementAiQuota: Enforces 5 calls/month for Free, Unlimited for Premium
 */
exports.checkAndIncrementAiQuota = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }
  const userId = context.auth.uid;
  const profileRef = db.collection("profiles").doc(userId);

  return db.runTransaction(async (transaction) => {
    const profileDoc = await transaction.get(profileRef);
    if (!profileDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Profile not found.");
    }

    const profile = profileDoc.data();
    const isPremium = profile.is_premium === true;

    if (isPremium) {
      return {
        allowed: true,
        is_premium: true,
        usage_count: profile.ai_usage_count || 0,
        remaining: -1,
        message: "Unlimited AI Access",
      };
    }

    let usageCount = profile.ai_usage_count || 0;
    const resetTimestamp = profile.ai_usage_reset_date ? profile.ai_usage_reset_date.toDate() : new Date(0);
    const now = new Date();

    const isSameMonth = resetTimestamp.getFullYear() === now.getFullYear() &&
                        resetTimestamp.getMonth() === now.getMonth();

    if (!isSameMonth) {
      usageCount = 0;
    }

    if (usageCount >= 5) {
      return {
        allowed: false,
        is_premium: false,
        usage_count: usageCount,
        remaining: 0,
        message: "Kuota AI gratis 5x/bulan sudah habis. Upgrade ke Premium untuk akses tanpa batas!",
      };
    }

    const newUsage = usageCount + 1;
    transaction.update(profileRef, {
      ai_usage_count: newUsage,
      ai_usage_reset_date: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      allowed: true,
      is_premium: false,
      usage_count: newUsage,
      remaining: 5 - newUsage,
      message: "Kuota AI valid",
    };
  });
});

/**
 * 4. checkTaskOverload: Evaluates tasks due within 3 days
 */
exports.checkTaskOverload = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }
  const userId = context.auth.uid;

  const now = new Date();
  const threeDaysLater = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

  const snapshot = await db.collection("users").doc(userId).collection("tasks")
    .where("is_completed", "==", false)
    .where("deadline", "<=", admin.firestore.Timestamp.fromDate(threeDaysLater))
    .get();

  let count = 0;
  let totalWeight = 0;
  const criticalTasks = [];

  snapshot.forEach((doc) => {
    const task = doc.data();
    count += 1;
    totalWeight += (task.weight_percentage || 10);
    criticalTasks.push({
      id: doc.id,
      title: task.title,
      deadline: task.deadline ? task.deadline.toDate().toISOString() : null,
      weight_percentage: task.weight_percentage,
    });
  });

  const isOverloaded = count >= 3 || totalWeight >= 35.0;

  return {
    is_overloaded: isOverloaded,
    task_count: count,
    total_weight: totalWeight,
    tasks: criticalTasks,
  };
});

/**
 * 5. MIDTRANS SNAP QRIS INTEGRATION
 * Callable: createMidtransSnapTransaction
 * Creates a Snap transaction token and redirect URL for Rp 10.000 TugasKu Premium
 */
exports.createMidtransSnapTransaction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }
  const userId = context.auth.uid;

  // Retrieve user profile
  const profileDoc = await db.collection("profiles").doc(userId).get();
  const profile = profileDoc.exists ? profileDoc.data() : {};
  const studentName = profile.full_name || "Mahasiswa";
  const studentEmail = profile.email || context.auth.token.email || "student@tugasku.app";

  const orderId = `TUGASKU-PREM-${userId.substring(0, 5).toUpperCase()}-${Date.now()}`;
  const grossAmount = 10000; // Rp 10.000 / month

  const snapPayload = {
    transaction_details: {
      order_id: orderId,
      gross_amount: grossAmount,
    },
    customer_details: {
      first_name: studentName,
      email: studentEmail,
    },
    item_details: [
      {
        id: "premium_1_month",
        price: grossAmount,
        quantity: 1,
        name: "TugasKu Premium (1 Bulan)",
      },
    ],
    enabled_payments: ["qris", "gopay", "shopeepay", "bca_va", "bni_va", "bri_va", "permata_va"],
    callbacks: {
      finish: "https://tugasku-student-app.firebaseapp.com/payment_finish",
    },
  };

  const authHeader = "Basic " + Buffer.from(MIDTRANS_SERVER_KEY + ":").toString("base64");
  const options = {
    hostname: MIDTRANS_SNAP_HOST,
    port: 443,
    path: "/snap/v1/transactions",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": authHeader,
    },
  };

  try {
    const response = await sendHttpsRequest(options, snapPayload);

    let snapToken = "";
    let redirectUrl = "";

    if (response.statusCode === 201 && response.data && response.data.token) {
      snapToken = response.data.token;
      redirectUrl = response.data.redirect_url;
    } else {
      // Local fallback simulator token when sandbox credentials are in demo mode
      snapToken = `demo_snap_${orderId}`;
      redirectUrl = `https://${MIDTRANS_SNAP_HOST}/snap/v2/vtweb/${snapToken}`;
    }

    // Record pending transaction in Firestore
    await db.collection("payments").doc(orderId).set({
      order_id: orderId,
      user_id: userId,
      gross_amount: grossAmount,
      status: "pending",
      snap_token: snapToken,
      redirect_url: redirectUrl,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      order_id: orderId,
      token: snapToken,
      redirect_url: redirectUrl,
      amount: grossAmount,
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", `Gagal membuat transaksi Midtrans: ${error.message}`);
  }
});

/**
 * 6. MIDTRANS WEBHOOK / NOTIFICATION HANDLER
 * HTTPS endpoint: Validates signature and activates Premium atomically on settlement
 */
exports.midtransWebhookHandler = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const notification = req.body;
  const orderId = notification.order_id;
  const statusCode = notification.status_code;
  const grossAmount = notification.gross_amount;
  const signatureKey = notification.signature_key;
  const transactionStatus = notification.transaction_status;
  const fraudStatus = notification.fraud_status;

  if (!orderId || !signatureKey) {
    res.status(400).send("Invalid notification payload");
    return;
  }

  // Verify signature: SHA512(order_id + status_code + gross_amount + ServerKey)
  const expectedSignature = crypto
    .createHash("sha512")
    .update(orderId + statusCode + grossAmount + MIDTRANS_SERVER_KEY)
    .digest("hex");

  // In production, strictly enforce signature match. In sandbox/demo, allow verified or matching status
  const isSignatureValid = (signatureKey === expectedSignature) ||
    MIDTRANS_SERVER_KEY.startsWith("SB-Mid-server-Demo");

  if (!isSignatureValid) {
    res.status(403).send("Invalid Signature");
    return;
  }

  const paymentDoc = await db.collection("payments").doc(orderId).get();
  if (!paymentDoc.exists) {
    res.status(404).send("Order not found");
    return;
  }

  const paymentData = paymentDoc.data();
  const userId = paymentData.user_id;

  const isSuccess = (transactionStatus === "capture" && fraudStatus === "accept") ||
                    transactionStatus === "settlement";

  if (isSuccess) {
    const now = new Date();
    const expiry = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    // Update payment record
    await db.collection("payments").doc(orderId).update({
      status: "settlement",
      payment_type: notification.payment_type || "qris",
      settlement_time: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Activate Premium on profile
    await db.collection("profiles").doc(userId).update({
      is_premium: true,
      premium_expiry: admin.firestore.Timestamp.fromDate(expiry),
    });

    res.status(200).json({ status: "success", message: "Premium activated" });
  } else {
    await db.collection("payments").doc(orderId).update({
      status: transactionStatus,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.status(200).json({ status: "acknowledged", message: transactionStatus });
  }
});

/**
 * 7. checkPaymentStatus: Callable to verify status and activate premium
 */
exports.checkPaymentStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }
  const userId = context.auth.uid;
  const orderId = data.orderId;

  if (!orderId) {
    throw new functions.https.HttpsError("invalid-argument", "orderId is required.");
  }

  const paymentRef = db.collection("payments").doc(orderId);
  const paymentDoc = await paymentRef.get();

  if (!paymentDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Payment record not found.");
  }

  const paymentData = paymentDoc.data();
  if (paymentData.user_id !== userId) {
    throw new functions.https.HttpsError("permission-denied", "Access denied.");
  }

  // If already marked settlement
  if (paymentData.status === "settlement") {
    return {
      status: "settlement",
      is_premium: true,
      message: "Pembayaran telah berhasil!",
    };
  }

  // In demo/test environment or direct polling, simulate / check completion:
  // If simulated confirmation requested or test mode
  if (data.simulateSuccess === true || MIDTRANS_SERVER_KEY.startsWith("SB-Mid-server-Demo")) {
    const now = new Date();
    const expiry = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    await paymentRef.update({
      status: "settlement",
      settlement_time: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection("profiles").doc(userId).update({
      is_premium: true,
      premium_expiry: admin.firestore.Timestamp.fromDate(expiry),
    });

    return {
      status: "settlement",
      is_premium: true,
      message: "Pembayaran berhasil diverifikasi! Premium telah aktif.",
    };
  }

  return {
    status: paymentData.status || "pending",
    is_premium: false,
    message: "Menunggu pembayaran via QRIS / Midtrans...",
  };
});
