.PHONY: ios android clean test analyze format

ios:
	flutter run -d iphone

android:
	flutter run -d android

clean:
	flutter clean

test:
	flutter test

analyze:
	flutter analyze

format:
	dart format .

get:
	flutter pub get

build-ios:
	flutter build ios

build-apk:
	flutter build apk

doctor:
	flutter doctor