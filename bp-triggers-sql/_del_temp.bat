@rem This file in DOS codepage for correct view russian characters in console,
@rem please view and edit in Notepad++

@rem Создано vshestakov 2017-05-11
@rem Удаляет временные файлы в каталоге по маске

@rem ИСТОРИЯ ВЕРСИЙ
@rem v01 2017-05-11 vshestakov Первая версия
@rem v02 2017-11-16 vshestakov Добавлена маска удаления ~*.*

@echo off
echo Удаляю временные файлы...
echo.

del *.~*
del ~*.*

echo.
echo Файлы удалены.
echo.

rem pause