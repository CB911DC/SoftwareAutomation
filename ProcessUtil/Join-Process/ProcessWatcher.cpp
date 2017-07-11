#include "stdafx.h"
#include "ProcessWatcher.h"
#include "ProcessUtils.h"
#include <algorithm>

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
	this->isSubProcess = isChildWatcher;
	this->isFinished = false;
	this->exitCode = 0;
	this->waitForChilds = waitForChilds;
}

ProcessWatcher::~ProcessWatcher() {
	CloseHandle(this->hProc);
	this->hProc = INVALID_HANDLE_VALUE;
	subWatchers.clear();
}

int ProcessWatcher::Join(bool waitForChilds) {
	this->waitForChilds = waitForChilds;
	if (this->isSubProcess) {
		assert(false);
		return 0;
	}
	while (subWatchers.size() > 0 || !this->isFinished) {
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
	if (this->isSubProcess) {
		std::cout << " > ";
	}
	std::cout << "pid " << this->pid << " finished: " << this->isFinished << " (" << this->exitCode << ")" << std::endl;
	for (auto child = this->subWatchers.begin(); child != this->subWatchers.end(); ++child)
	{
		child->second->LogStatus();
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
		using namespace std::placeholders;
		FindChildProcesses(this->pid, std::bind(&ProcessWatcher::HandleChildProcess, this, _1));
		CheckChildProcesses();
	}
}

void ProcessWatcher::HandleChildProcess(const PROCESSENTRY32& entry) {
	DWORD pid = entry.th32ProcessID;
	if (this->subWatchers.find(pid) != this->subWatchers.end()) {
		return; //already known!
	}
	if (this->beVerbose) {
		std::cout << "child process detected! (" << pid << ")" << std::endl;
	}
	HANDLE hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
	this->subWatchers[pid] = std::make_shared<ProcessWatcher>(hProc, this->beVerbose, this->checkInterval, true, true);
}

void ProcessWatcher::CheckChildProcesses() {
	for (auto child = this->subWatchers.begin(); child != this->subWatchers.end();)
	{
		child->second->CheckProcess();
		if (child->second->isFinished && 0 == child->second->subWatchers.size()) {
			this->subWatchers.erase(child++);
		}
		else {
			++child;
		}
	}
}
