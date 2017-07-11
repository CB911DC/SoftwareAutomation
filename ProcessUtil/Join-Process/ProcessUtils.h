#pragma once
#include <string>
#include <functional>

typedef void* HANDLE;
typedef std::function<void(const PROCESSENTRY32&)> ProcessEntryHandler;

HANDLE GetProcessById(DWORD id);
HANDLE GetProcessByName(const std::string& str);
void ForEachProcess(ProcessEntryHandler callback);
void FindChildProcesses(DWORD pid, ProcessEntryHandler callback);

