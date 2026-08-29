// backend/src/middleware/auth.js
const admin = require('firebase-admin');
const { getUserById } = require('../models/User');

// تهيئة Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(require('../../config/firebase-admin.json')),
  });
}

const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: '❌ غير مصرح: لم يتم توفير توكن' });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // جلب معلومات المستخدم من قاعدة البيانات
    const user = await getUserById(decodedToken.uid);
    if (!user) {
      return res.status(404).json({ error: '❌ المستخدم غير موجود' });
    }

    // إضافة معلومات المستخدم إلى كائن الطلب للاستخدام لاحقاً
    req.user = { ...decodedToken, ...user };
    next();
  } catch (error) {
    console.error('❌ خطأ في التحقق من التوكن:', error);
    return res.status(401).json({ error: '❌ توكن غير صالح أو منتهي الصلاحية' });
  }
};

// للتحقق من صلاحية المشترك (اشتراك مدفوع)
const requireSubscription = (req, res, next) => {
  if (!req.user || !req.user.isSubscribed) {
    return res.status(403).json({ 
      error: '⚠️ هذا المحتوى حصري للمشتركين، يرجى الاشتراك للوصول إليه' 
    });
  }
  next();
};

module.exports = { verifyToken, requireSubscription };