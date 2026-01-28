@echo off
echo Building TypeScript...
call npx vue-tsc
if errorlevel 1 (
    echo TypeScript build failed!
    exit /b 1
)
echo Building Vite...
call npx vite build
if errorlevel 1 (
    echo Vite build failed!
    exit /b 1
)
echo Build completed successfully!
