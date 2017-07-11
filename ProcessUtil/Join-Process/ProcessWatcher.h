#pragma once
#include <map>
#include <memory>

class ProcessWatcher {
public:
	typedef std::shared_ptr<ProcessWatcher> ProcessWatcherPtr;

public:
	ProcessWatcher(HANDLE hProc, bool beVerbose, int interval, bool isChildWatcher, bool waitForChilds);
	ProcessWatcher(HANDLE hProc, bool beVerbose, int interval = 1);
	~ProcessWatcher();

	int Join(bool waitForChilds = false);

private:
	void Init(HANDLE hProc, bool beVerbose, int interval, bool isChildWatcher, bool waitForChilds);
	void LogStatus();
	void CheckProcess();
	void CheckChildProcesses();
	void HandleChildProcess(const PROCESSENTRY32& entry);

private:
	ProcessWatcher(const ProcessWatcher& a); //forbid copy!
	ProcessWatcher& operator=(const ProcessWatcher& a); //forbid copy!

private:
	bool beVerbose;
	HANDLE hProc;
	DWORD pid;
	int checkInterval;
	bool isFinished;
	DWORD exitCode;
	bool isSubProcess;
	bool waitForChilds;
	std::map<DWORD, ProcessWatcherPtr> subWatchers;
};
