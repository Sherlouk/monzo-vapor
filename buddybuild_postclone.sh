#!/usr/bin/env bash

brew tap vapor/homebrew-tap
brew update
brew install vapor

swift package generate-xcodeproj
