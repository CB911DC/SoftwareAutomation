#pragma once
#include <wtypes.h>
#include <list>
#include <memory>

class ProcessWatcher {
private:
	bool beVerbose;
	HANDLE hProc;
	DWORD pid;
	int checkInterval;
	bool isFinished;
	DWORD exitCode;
	bool isChildWatcher;
	bool waitForChilds;
	std::list<std::shared_ptr<ProcessWatcher>> childWatchers;

public:
	ProcessWatcher(HANDLE hProc, bool beVerbose, int interval, bool isChildWatcher, bool waitForChilds);
	ProcessWatcher(HANDLE hProc, bool beVerbose, int interval = 1);
	~ProcessWatcher();

	int Join(bool waitForChilds = false);

private:
	void Init(HANDLE hProc, bool beVerbose, int interval, bool isChildWatcher, bool waitForChilds);
	void CheckProcess();
	void CheckForChildProcesses(HANDLE snapshot);
	void HandleChildProcess(const PROCESSENTRY32& entry);

private:
	ProcessWatcher(const ProcessWatcher& a); //forbid copy!
	ProcessWatcher& operator=(const ProcessWatcher& a); //forbid copy!
	void LogStatus();
};
