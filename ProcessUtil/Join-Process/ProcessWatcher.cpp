#include "stdafx.h"
#include "ProcessWatcher.h"


ProcessWatcher::ProcessWatcher(HANDLE hProc, bool beVerbose, int interval /*= 1*/) {
	Init(hProc, beVerbose, interval, false, false);
}

ProcessWatcher::ProcessWatcher(HANDLE hProc, bool beBerbose, int interval, bool isChildWatcher, bool waitForChilds) {
	Init(hProc, beVerbose, interval, isChildWatcher, waitForChilds);
}

void ProcessWatcher::Init(HANDLE hProc, bool beVerbose, int interval, bool isChildWatcher, bool waitForChilds) {
	this->hProc = hProc;
	this->pid = GetProcessId(this->hProc);
	this->beVerbose = beVerbose;
	this->checkInterval = interval;
	this->isChildWatcher = isChildWatcher;
	this->isFinished = false;
	this->exitCode = 0;
	this->waitForChilds = waitForChilds;
}

ProcessWatcher::~ProcessWatcher() {
	CloseHandle(this->hProc);
	this->hProc = INVALID_HANDLE_VALUE;
	childWatchers.clear();
}

int ProcessWatcher::Join(bool waitForChilds) {
	this->waitForChilds = waitForChilds;
	if (this->isChildWatcher) {
		assert(false);
		return 0;
	}
	while (childWatchers.size() > 0 || !this->isFinished) {
		Sleep(this->checkInterval * 1000);
		CheckProcess();
		LogStatus();
	}
	return this->exitCode;
}

void ProcessWatcher::LogStatus() {
	if (!this->beVerbose) {
		return;
	}
	if (this->isChildWatcher) {
		std::cout << " > ";
	}
	std::cout << "pid " << this->pid << " finished: " << this->isFinished << " (" << this->exitCode << ")" << std::endl;
	for (auto child = this->childWatchers.begin(); child != this->childWatchers.end();++child)
	{
		(*child)->LogStatus();
	}
}

void ProcessWatcher::CheckProcess() {
	if (!this->isFinished) {
		if (GetExitCodeProcess(this->hProc, &this->exitCode)) {
			if (STATUS_PENDING != this->exitCode) {
				this->isFinished = true;
			}
		}
	}
	if (this->waitForChilds) {
		HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
		CheckForChildProcesses(snapshot);
		CloseHandle(snapshot);

		for (auto child = this->childWatchers.begin(); child != this->childWatchers.end();)
		{
			(*child)->CheckProcess();
			if ((*child)->isFinished && 0 == (*child)->childWatchers.size()) {
				this->childWatchers.erase(child++);
			}
			else {
				++child;
			}
		}
	}
}

void ProcessWatcher::CheckForChildProcesses(HANDLE snapshot) {
	PROCESSENTRY32 entry;
	entry.dwSize = sizeof(PROCESSENTRY32);
	if (TRUE == Process32First(snapshot, &entry))
	{
		while (TRUE == Process32Next(snapshot, &entry))
		{
			if (entry.th32ParentProcessID == this->pid) {
				HandleChildProcess(entry);
			}
		}
	}
}

void ProcessWatcher::HandleChildProcess(const PROCESSENTRY32& entry) {
	DWORD pid = entry.th32ProcessID;
	for (auto child = this->childWatchers.begin(); child != this->childWatchers.end();++child)
	{
		if ((*child)->pid == pid) {
			return; // already known!
		}
	}
	if (this->beVerbose) {
		std::cout << "child process detected! (" << pid << ")" << std::endl;
	}
	HANDLE hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
	this->childWatchers.push_back(std::make_shared<ProcessWatcher>(hProc, this->beVerbose, this->checkInterval, true, true));
}