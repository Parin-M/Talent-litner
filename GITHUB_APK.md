# ساخت APK با GitHub Actions — Talent Litner v2

این پروژه برای ساخت APK بدون Android Studio آماده شده است.

## استفاده

1. کل پروژه را داخل یک GitHub Repository قرار بده.
2. وارد تب **Actions** شو.
3. Workflow با نام **Build Talent Litner APK** را انتخاب کن.
4. روی **Run workflow** بزن.
5. بعد از اتمام موفق، وارد اجرای Workflow شو و از بخش **Artifacts** فایل `talent-litner-release-apk` را دانلود کن.

Workflow در سرور GitHub، Flutter و Java را آماده می‌کند و Android platform/Gradle files را نیز در CI تولید می‌کند؛ بنابراین لازم نیست Android Studio روی کامپیوترت نصب باشد.

## ساخت خودکار

Workflow روی push به شاخه `main` یا `master` نیز اجرا می‌شود.
