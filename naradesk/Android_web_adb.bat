@echo off
adb start-server
adb reverse tcp:8080 tcp:8080
exit