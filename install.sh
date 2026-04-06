#!/bin/sh
# install.sh - تثبيت إضافات STB_UNION E2
# للمالك: ilyasM6

# الألوان للإخراج الجميل
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${GREEN}========================================${NC}"
echo "${GREEN}   تثبيت STB_UNION E2 Plugins${NC}"
echo "${GREEN}========================================${NC}"

# التحقق من صلاحيات الجذر (مطلوب لـ Enigma2)
if [ "$(id -u)" != "0" ]; then
    echo "${RED}خطأ: يجب تشغيل هذا السكريبت بصلاحيات الجذر (root)${NC}"
    echo "قم بتشغيل: sudo $0"
    exit 1
fi

# تحديد مسار التثبيت (افتراضي لنظام Enigma2)
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions"
TEMP_DIR="/tmp/stb_union_install"

# إنشاء مجلد مؤقت
echo "${YELLOW}إنشاء مجلد مؤقت...${NC}"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# فك الضغط
echo "${YELLOW}فك ضغط الملف...${NC}"
tar -xzf "STB_UNION E2.tar.gz" -C $TEMP_DIR

if [ $? -ne 0 ]; then
    echo "${RED}فشل في فك الضغط. تأكد من وجود الملف STB_UNION E2.tar.gz${NC}"
    exit 1
fi

# نسخ الملفات إلى مسار الإضافات
echo "${YELLOW}تثبيت الإضافات...${NC}"
cp -rf $TEMP_DIR/* $PLUGIN_DIR/

if [ $? -eq 0 ]; then
    echo "${GREEN}تم التثبيت بنجاح!${NC}"
else
    echo "${RED}حدث خطأ أثناء النسخ${NC}"
    exit 1
fi

# تنظيف الملفات المؤقتة
echo "${YELLOW}تنظيف...${NC}"
rm -rf $TEMP_DIR

# إعادة تشغيل واجهة Enigma2
echo "${GREEN}========================================${NC}"
read -p "هل تريد إعادة تشغيل واجهة Enigma2؟ (y/n): " RESTART
if [ "$RESTART" = "y" ] || [ "$RESTART" = "Y" ]; then
    echo "${YELLOW}جاري إعادة تشغيل واجهة Enigma2...${NC}"
    killall -9 enigma2
    echo "${GREEN}تم إعادة التشغيل${NC}"
else
    echo "${YELLOW}يرجى إعادة تشغيل واجهة Enigma2 يدويًا لتفعيل الإضافات${NC}"
    echo "يمكنك التشغيل باستخدام: killall -9 enigma2"
fi

echo "${GREEN}اكتمل التثبيت!${NC}"
