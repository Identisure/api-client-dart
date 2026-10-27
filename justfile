build:
    dart pub get

test:
    dart test

check:
    dart format --output=none --set-exit-if-changed .
    dart analyze

publish:
    dart pub publish
