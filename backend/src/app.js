// backend/src/app.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 🔐 تهيئة Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, '..', 'config', 'firebase-admin.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ ملف المفتاح غير موجود في:', serviceAccountPath);
  console.error('📌 تأكد من وجود ملف firebase-admin.json في مجلد config');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://comicy.firebaseio.com"
});

console.log('✅ تم الاتصال بـ Firebase بنجاح');

const db = admin.firestore();
const app = express();
// backend/src/app.js

// ... (باقي الكود)

// ✅ خدمة الملفات الثابتة من مجلد uploads
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// 🔒 طبقات الأمان
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// تحديد معدل الطلبات
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: '❗ تجاوزت الحد المسموح من الطلبات، حاول لاحقاً',
});
app.use('/api/', limiter);

// 📡 مسار اختبار
app.get('/api/test', (req, res) => {
  res.json({ 
    status: 'success', 
    message: '✅ الخادم يعمل بنجاح!',
    time: new Date().toISOString()
  });
});

// 📡 جلب المحتوى من Firestore
app.get('/api/content', async (req, res) => {
  try {
    const contentRef = db.collection('content');
    const snapshot = await contentRef.get();
    
    if (snapshot.empty) {
      return res.status(404).json({ 
        status: 'error',
        message: '❌ لا يوجد محتوى في قاعدة البيانات' 
      });
    }
    
    const results = [];
    snapshot.forEach(doc => {
      results.push({ id: doc.id, ...doc.data() });
    });
    
    res.json({ status: 'success', data: results });
  } catch (error) {
    console.error('❌ خطأ في جلب المحتوى:', error);
    res.status(500).json({ 
      status: 'error',
      message: '❌ فشل في جلب المحتوى' 
    });
  }
});

// 📡 البحث في المحتوى
app.get('/api/search', async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q || q.trim().length < 2) {
      return res.status(400).json({ 
        status: 'error',
        message: '❌ يجب أن يكون البحث على الأقل حرفين' 
      });
    }

    const searchTerm = q.trim().toLowerCase();
    const contentRef = db.collection('content');
    const snapshot = await contentRef.get();

    if (snapshot.empty) {
      return res.json({ 
        status: 'success', 
        data: [],
        message: '⚠️ لا يوجد محتوى للبحث' 
      });
    }

    const results = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      const title = (data.title || '').toLowerCase();
      const tags = (data.tags || []).map(tag => tag.toLowerCase());
      
      if (title.includes(searchTerm) || tags.some(tag => tag.includes(searchTerm))) {
        results.push({ id: doc.id, ...data });
      }
    });

    res.json({ status: 'success', data: results, count: results.length });
  } catch (error) {
    console.error('❌ خطأ في البحث:', error);
    res.status(500).json({ 
      status: 'error',
      message: '❌ فشل في البحث' 
    });
  }
});

// الصفحة الرئيسية
app.get('/', (req, res) => {
  res.json({ 
    status: 'success', 
    message: 'مرحباً في خادم كوميكس دايلي',
    version: '1.0.0',
    endpoints: {
      test: '/api/test',
      content: '/api/content',
      search: '/api/search?q=نكتة'
    }
  });
});

// معالج الأخطاء
app.use((err, req, res, next) => {
  console.error('❌ خطأ غير متوقع:', err);
  res.status(500).json({
    status: 'error',
    message: '⚠️ حدث خطأ داخلي في الخادم'
  });
});

module.exports = app;