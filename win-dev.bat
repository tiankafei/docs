cd /d %~dp0
echo %~dp0

call java -jar node-1.0-SNAPSHOT-jar-with-dependencies.jar
call yarn docs:dev

pause