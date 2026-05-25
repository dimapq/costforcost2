# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['frontend/main.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('frontend/qml', 'frontend/qml'),
        ('backend', 'backend'),
        ('newlogo.png', '.'),
        ('logo.png', '.'),
        ('prelogo.png', '.'),
        ('prelogo', 'prelogo'),
        ('logo.ico', '.'),
        ('version.py', '.'),
    ],
    hiddenimports=['psycopg2', 'pandas', 'openpyxl', 'requests', 'bs4', 'lxml', 'configparser', 'backend.db.config'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='MachineCostPro',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='logo.ico',
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='MachineCostPro',
)
