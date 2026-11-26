# Not the place for the engine

AGP refuses `implementation(files("...aar"))` on an Android **library** module, which is what a
Flutter plugin is — `bundleDebugAar` fails. The engine therefore comes in through a flat artifact
module instead:

```text
example/android/libfacesdk/facerecognitionsdk.aar
```

`settings.gradle.kts` already includes `:libfacesdk`, and this plugin depends on it when present.
For your own app, copy `example/android/libfacesdk/` into your Android project, drop the AAR there
and add `include(":libfacesdk")` to your `settings.gradle`.
