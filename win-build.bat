cd /d %~dp0
echo %~dp0

call rd /q/s %~dp0dist
call java -jar node-1.0-SNAPSHOT-jar-with-dependencies.jar
call yarn docs:build

pause