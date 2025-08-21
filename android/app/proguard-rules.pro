# Flutter & AndroidX baseline keeps
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }

# flutter_local_notifications plugin classes
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep notification channel sound resource references
# -keepresourcexmlelements manifest/application/* (not supported in R8)

# Keep enum names
-keepclassmembers enum * { *; }

# Keep classes with annotations (common in plugins)
-keepattributes *Annotation*

# Ignore missing Google Play Core classes (not needed for standard APK)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }