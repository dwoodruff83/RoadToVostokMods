@echo off
REM Wrapper for tools\godot_docs_mcp\download_docs.py.
REM Forwards all args; see the script for usage.
python "%~dp0tools\godot_docs_mcp\download_docs.py" %*
