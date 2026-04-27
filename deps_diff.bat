@echo off
REM ----------------------------------------------------------------------------
REM Calls into the rtv-mod-impact-tracker tool — a separate repo not bundled
REM here. Clone it at F:\rtv-mod-impact-tracker\ (or update the path below) to
REM use this wrapper. See README.md "Version Tracking" for setup details.
REM ----------------------------------------------------------------------------
python F:\rtv-mod-impact-tracker\deps_diff.py %*
