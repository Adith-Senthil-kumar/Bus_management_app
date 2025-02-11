/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.resetAttendance = functions.pubsub.schedule('every day 00:00').onRun(async (context) => {
  const studentsRef = admin.firestore().collection('students');
  const snapshot = await studentsRef.get();

  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, { present: false });
  });

  await batch.commit();
  console.log('Attendance reset for all students');
});

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotifications = functions.https.onRequest(async (req, res) => {
  const { title, message } = req.body;

  if (!title || !message) {
    res.status(400).send('Title and message are required');
    return;
  }

  try {
    const tokensSnapshot = await admin.firestore().collection('tokens').get();
    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

    const payload = {
      notification: {
        title: title,
        body: message,
      },
    };

    const response = await admin.messaging().sendToDevice(tokens, payload);
    res.status(200).send(`${response.successCount} notifications sent successfully`);
  } catch (error) {
    res.status(500).send('Error sending notifications: ' + error.message);
  }
});