# ساخت APK با GitHub Actions — Parin Litner v2

این پروژه برای ساخت APK بدون Android Studio آماده شده است.

## استفاده

1. کل پروژه را داخل یک GitHub Repository قرار بده.
2. وارد تب **Actions** شو.
3. Workflow با نام **Build Parin Litner APK** را انتخاب کن.
4. روی **Run workflow** بزن.
5. بعد از اتمام موفق، وارد اجرای Workflow شو و از بخش **Artifacts** فایل `parin-litner-release-apk` را دانلود کن.

Workflow در سرور GitHub، Flutter و Java را آماده می‌کند و Android platform/Gradle files را نیز در CI تولید می‌کند؛ بنابراین لازم نیست Android Studio روی کامپیوترت نصب باشد.

نسخهٔ فعلی فقط برای **Android 7.0 به بالا (API 24+)** ساخته می‌شود؛ ساخت APK قدیمی Android 4 دیگر بخشی از CI نیست.

## ساخت خودکار

Workflow روی push به شاخه `main` یا `master` نیز اجرا می‌شود.
