
# FirePlace

An app to guide open burning activities using weather and location data to analyse and determine the risk of creating an open fire using a Large Language Model. Provides a heatmap to suggest suitable spots for an open fire according to AI analysis.

Kitahack 2025 submission for group KitaTakRetiHack.


## Installation

The following are the steps to run the project\
1\. Go to root directory and install flutter packages:

```bash
  flutter pub get
```

2\. Add Google Maps API key to Android/iOS manifest

#### Android
In ```android/app/src/main/AndroidManifest.xml```
```xml
<manifest ...
  <application ...
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR KEY HERE"/>
```

#### iOS
Refer the google_maps_flutter [documentation](https://pub.dev/packages/google_maps_flutter#ios)


3\. Add Gemini API key to .env (make sure it's in the root directory!)

```bash
  echo "GEMINI_API_KEY='your_api_key'" > .env
```

4\. Run the program

```bash
  flutter run
```