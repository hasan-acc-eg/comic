// تهيئة Supabase
const SUPABASE_URL = 'https://aawxuuubcpxdwurdvudozd.supabase.co';
const SUPABASE_KEY = 'sb_publishable_8bTYwwLF4_uneY0JFRuisQ_WBDrKBAZ'; // ⚠️ استبدل بالمفتاح الكامل

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// ==== التبديل بين التبويبات ====
document.querySelectorAll('nav ul li').forEach(tab => {
    tab.addEventListener('click', function() {
        document.querySelectorAll('nav ul li').forEach(t => t.classList.remove('active'));
        this.classList.add('active');
        
        const tabId = this.dataset.tab;
        document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
        document.getElementById(tabId).classList.add('active');
        
        if (tabId === 'dashboard') loadDashboard();
        if (tabId === 'manage') loadContent();
        if (tabId === 'categories') loadCategories();
    });
});

// ==== رفع الملف ====
document.getElementById('upload-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const title = document.getElementById('title').value;
    const type = document.getElementById('content-type').value;
    const description = document.getElementById('description').value;
    const tags = document.getElementById('tags').value.split(',').map(t => t.trim());
    const file = document.getElementById('file-upload').files[0];
    
    if (!file) {
        alert('يرجى اختيار ملف');
        return;
    }
    
    const statusDiv = document.getElementById('upload-status');
    statusDiv.innerHTML = '⏳ جاري الرفع...';
    
    try {
        // 1. رفع الملف إلى Storage
        const filePath = `uploads/${Date.now()}_${file.name}`;
        const { data: uploadData, error: uploadError } = await supabase.storage
            .from('comic-files')
            .upload(filePath, file);
        
        if (uploadError) throw uploadError;
        
        // 2. الحصول على الرابط العام
        const { data: urlData } = supabase.storage
            .from('comic-files')
            .getPublicUrl(filePath);
        
        // 3. حفظ البيانات في جدول content
        const { data: contentData, error: contentError } = await supabase
            .from('content')
            .insert([{
                title,
                type,
                description,
                file_path: urlData.publicUrl,
                tags,
                views: 0,
                shares: 0
            }]);
        
        if (contentError) throw contentError;
        
        statusDiv.innerHTML = '✅ تم رفع المحتوى بنجاح!';
        this.reset();
        document.getElementById('file-info').innerHTML = '';
        
        loadDashboard();
        
    } catch (error) {
        statusDiv.innerHTML = `❌ خطأ: ${error.message}`;
        console.error('Upload error:', error);
    }
});

// ==== عرض معلومات الملف ====
document.getElementById('file-upload').addEventListener('change', function() {
    const file = this.files[0];
    if (file) {
        document.getElementById('file-info').innerHTML = `
            📁 ${file.name} (${(file.size / 1024).toFixed(1)} كيلوبايت)
        `;
    }
});

// ==== تحميل لوحة التحكم ====
async function loadDashboard() {
    try {
        const { data: content, error } = await supabase
            .from('content')
            .select('*')
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        document.getElementById('total-content').textContent = content.length;
        document.getElementById('total-views').textContent = content.reduce((sum, c) => sum + (c.views || 0), 0);
        document.getElementById('total-shares').textContent = content.reduce((sum, c) => sum + (c.shares || 0), 0);
        
        const recentList = document.getElementById('recent-list');
        recentList.innerHTML = content.slice(0, 5).map(item => `
            <div class="content-item">
                <span>${item.title}</span>
                <span>${item.type} | ${new Date(item.created_at).toLocaleDateString('ar')}</span>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Dashboard error:', error);
    }
}

// ==== تحميل قائمة المحتوى ====
async function loadContent() {
    try {
        const { data: content, error } = await supabase
            .from('content')
            .select('*')
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        const listDiv = document.getElementById('content-list');
        listDiv.innerHTML = content.map(item => `
            <div class="content-item" data-id="${item.id}">
                <div>
                    <strong>${item.title}</strong>
                    <span style="color:#888;font-size:14px;margin-left:10px;">${item.type}</span>
                </div>
                <div>
                    <span style="color:#888;font-size:14px;">👁️ ${item.views || 0}</span>
                    <button class="btn-danger" onclick="deleteContent('${item.id}')">🗑️</button>
                </div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Load content error:', error);
    }
}

// ==== حذف محتوى ====
async function deleteContent(id) {
    if (!confirm('هل أنت متأكد من حذف هذا المحتوى؟')) return;
    
    try {
        const { error } = await supabase
            .from('content')
            .delete()
            .eq('id', id);
        
        if (error) throw error;
        
        loadContent();
        loadDashboard();
        
    } catch (error) {
        alert('خطأ في الحذف: ' + error.message);
    }
}

// ==== البحث في المحتوى ====
document.getElementById('search-content').addEventListener('input', async function() {
    const query = this.value.trim();
    if (query.length < 2) {
        loadContent();
        return;
    }
    
    try {
        const { data: content, error } = await supabase
            .from('content')
            .select('*')
            .ilike('title', `%${query}%`)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        const listDiv = document.getElementById('content-list');
        listDiv.innerHTML = content.map(item => `
            <div class="content-item" data-id="${item.id}">
                <div>
                    <strong>${item.title}</strong>
                    <span style="color:#888;font-size:14px;margin-left:10px;">${item.type}</span>
                </div>
                <div>
                    <span style="color:#888;font-size:14px;">👁️ ${item.views || 0}</span>
                    <button class="btn-danger" onclick="deleteContent('${item.id}')">🗑️</button>
                </div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Search error:', error);
    }
});

// ==== تحميل التصنيفات ====
async function loadCategories() {
    try {
        const { data: categories, error } = await supabase
            .from('categories')
            .select('*')
            .order('name');
        
        if (error) throw error;
        
        const listDiv = document.getElementById('category-list');
        listDiv.innerHTML = categories.map(cat => `
            <div class="content-item">
                <span>${cat.icon || '🏷️'} ${cat.name}</span>
                <span style="color:#888;font-size:14px;">${cat.slug}</span>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Load categories error:', error);
    }
}

// ==== إضافة تصنيف ====
document.getElementById('category-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const name = document.getElementById('category-name').value;
    const slug = document.getElementById('category-slug').value;
    
    try {
        const { data, error } = await supabase
            .from('categories')
            .insert([{ name, slug }]);
        
        if (error) throw error;
        
        this.reset();
        loadCategories();
        
    } catch (error) {
        alert('خطأ في الإضافة: ' + error.message);
    }
});

// ==== تحميل أولي للوحة التحكم ====
loadDashboard();
loadContent();
loadCategories();