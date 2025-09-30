setup:
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

analyze:
	dart format --set-exit-if-changed .
	flutter analyze

test:
	dart test

test:golden:
	flutter test --update-goldens

build:beta:
	flutter build apk --flavor beta --release

build:prod:
	flutter build apk --flavor prod --release
