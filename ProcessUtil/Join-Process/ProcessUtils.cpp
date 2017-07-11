#include "stdafx.h"
#include "ProcessUtils.h"
#include <list>


HANDLE GetProcessById(DWORD id) {
	return OpenProcess(PROCESS_ALL_ACCESS, FALSE, id);
}

HANDLE GetProcessByName(const std::string& name) {
	HANDLE hProc = INVALID_HANDLE_VALUE;
	ForEachProcess([name, &hProc](const PROCESSENTRY32& entry) -> HANDLE {
		std::wstring wsName(entry.szExeFile);
		std::string csName(wsName.begin(), wsName.end());
		if (0 == csName.compare(name))
		{
			if (INVALID_HANDLE_VALUE == hProc) {
				hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, entry.th32ProcessID);
			}
		}
	});
	return hProc;
}

void ForEachProcess(ProcessEntryHandler callback) {
	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
	PROCESSENTRY32 entry;
	entry.dwSize = sizeof(PROCESSENTRY32);
	if (TRUE == Process32First(snapshot, &entry))
	{
		while (TRUE == Process32Next(snapshot, &entry))
		{
			callback(entry);
		}
	}
	CloseHandle(snapshot);
}

void FindChildProcesses(DWORD pid, ProcessEntryHandler callback) {
	ProcessEntryHandler f = [pid, callback](const PROCESSENTRY32& entry) -> void {
		if (entry.th32ParentProcessID == pid) {
			callback(entry);
		}
	};
	ForEachProcess(f);
}
