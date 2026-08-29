// backend/src/controllers/contentController.js
const { searchContent, getContentById, incrementShareCount } = require('../models/Content');
const { createSignedUrl } = require('../utils/storage');

// البحث عن المحتوى
const search = async (req, res) => {
  try {
    const { q, type, limit = 20, page = 1 } = req.query;
    
    if (!q || q.trim().length < 2) {
      return res.status(400).json({ error: '❌ يجب أن يكون البحث على الأقل حرفين' });
    }

    // البحث في قاعدة البيانات
    const results = await searchContent(q.trim(), type, parseInt(limit), parseInt(page));
    
    // إنشاء روابط مؤقتة للملفات (تزيد الأمان)
    const secureResults = await Promise.all(results.map(async (item) => {
      const signedUrl = await createSignedUrl(item.filePath, 3600); // صلاحية ساعة
      return { ...item, fileUrl: signedUrl };
    }));

    res.json({
      status: 'success',
      results: secureResults,
      pagination: {
        currentPage: parseInt(page),
        limit: parseInt(limit),
        total: results.length // يمكن إضافة العدد الإجمالي من قاعدة البيانات
      }
    });
  } catch (error) {
    console.error('❌ خطأ في البحث:', error);
    res.status(500).json({ error: '❌ حدث خطأ أثناء البحث، حاول مرة أخرى' });
  }
};

// جلب محتوى معين بواسطة ID
const getContent = async (req, res) => {
  try {
    const { id } = req.params;
    const content = await getContentById(id);
    
    if (!content) {
      return res.status(404).json({ error: '❌ المحتوى غير موجود' });
    }

    // تتبع عدد المشاهدات (تحليلات)
    await incrementViewCount(id);

    // إنشاء رابط مؤقت للملف
    const signedUrl = await createSignedUrl(content.filePath, 3600);
    
    res.json({
      status: 'success',
      content: { ...content, fileUrl: signedUrl }
    });
  } catch (error) {
    console.error('❌ خطأ في جلب المحتوى:', error);
    res.status(500).json({ error: '❌ حدث خطأ أثناء جلب المحتوى' });
  }
};

// تسجيل عملية المشاركة (للتحليلات)
const trackShare = async (req, res) => {
  try {
    const { contentId, platform } = req.body;
    
    if (!contentId || !platform) {
      return res.status(400).json({ error: '❌ بيانات غير مكتملة' });
    }

    await incrementShareCount(contentId, platform);
    
    res.json({ status: 'success', message: '✅ تم تسجيل المشاركة' });
  } catch (error) {
    console.error('❌ خطأ في تتبع المشاركة:', error);
    res.status(500).json({ error: '❌ حدث خطأ' });
  }
};

module.exports = { search, getContent, trackShare };