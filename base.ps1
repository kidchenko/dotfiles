# Allow remote execution
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force;

#
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
