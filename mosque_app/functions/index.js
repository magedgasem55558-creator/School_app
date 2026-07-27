const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyParentOnGradeChange = functions.firestore
  .document('children/{childId}')
  .onWrite(async (change, context) => {
    const afterData = change.after.data();
    const beforeData = change.before.data();

    if (!afterData || !beforeData) return null;
    const oldPoints = beforeData.totalPoints || 0;
    const newPoints = afterData.totalPoints || 0;
    if (newPoints <= oldPoints) return null;

    const parentId = afterData.parentId;
    const childName = afterData.name || 'الابن';
    const addedPoints = newPoints - oldPoints;

    if (!parentId) return null;

    const parentDoc = await admin.firestore().collection('parents').doc(parentId).get();
    if (!parentDoc.exists) return null;

    const token = parentDoc.data().fcmToken;
    if (!token) return null;

    const payload = {
      notification: {
        title: 'تم إضافة درجة',
        body: `تم إضافة ${addedPoints} نقطة لـ ${childName}`,
      },
      data: {
        childId: context.params.childId,
        parentId: parentId,
      },
    };

    try {
      await admin.messaging().sendToDevice(token, payload);
      console.log(`إشعار أرسل إلى ${parentId}`);
    } catch (e) {
      console.error('فشل إرسال الإشعار:', e);
    }
    return null;
  });