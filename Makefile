clean-build:
	if exist "build" rd /s /q "build"

run-chrome: clean-build
	flutter run -d chrome --dart-define-from-file=.env

pub-get:
	flutter pub get
