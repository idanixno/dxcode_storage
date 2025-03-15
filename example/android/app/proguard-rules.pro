# نگهداری کلاس‌های مورد نیاز Tink
-keep class com.google.crypto.tink.** { *; }
-keepclassmembers class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# نگهداری annotations
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.annotations.**
-keepattributes *Annotation*
-keep class javax.annotation.** { *; }
-keep class com.google.errorprone.annotations.** { *; }

# جلوگیری از حذف کلاس‌های اشاره‌شده
-keep class javax.annotation.Nullable { *; }
-keep class javax.annotation.concurrent.GuardedBy { *; }
 