// Join-Process.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "InputParser.hpp"
#include "ProcessWatcher.h"

const char* ARG_VERBOSE = "-v";
const char* ARG_INTERVAL = "-i";
const char* ARG_F_BY_NAME = "-name";
const char* ARG_F_BY_ID = "-pid";
const char* ARG_WAIT_FOR_CHILDREN = "-wait-for-children";

void PrintUsage() {
	std::cout << "Join-Process.exe " << std::endl;
	std::cout << "usage: Join-Process [-pid <pid> | -name <process name>] [-i <sec>] [-wait-for-children] [-v] [-help]" << std::endl;
	std::cout << std::endl;
	std::cout << "\t-help .................... Print this help text" << std::endl;
	std::cout << "\t" << ARG_VERBOSE << "  ...................... be verbose" << std::endl;
	std::cout << "\t" << ARG_F_BY_ID << "  .................... attaches to a process by its id" << std::endl;
	std::cout << "\t" << ARG_F_BY_NAME << "  ................... attaches to a process by its name" << std::endl;
	std::cout << "\t" << ARG_INTERVAL << "  ...................... specify the interval (in seconds) to check for changes (default is 1)" << std::endl;
	std::cout << "\t" << ARG_WAIT_FOR_CHILDREN << "  ...... wait until all of the processes child processes also terminated" << std::endl;
	std::cout << std::endl;
}

bool CheckParamsValid(const InputParser& input) {
	if (input.cmdOptionExists("-h") || input.cmdOptionExists("-help") || 0 == input.getTokenCount()) {
		PrintUsage();
		return false;
	}
	if (!input.cmdOptionExists(ARG_F_BY_ID) && !input.cmdOptionExists(ARG_F_BY_NAME)) {
		std::cerr << "specify '" << ARG_F_BY_ID << "' or '" << ARG_F_BY_NAME << "'" << std::endl;
		return false;
	}
	if (input.cmdOptionExists(ARG_F_BY_ID) && input.cmdOptionExists(ARG_F_BY_NAME)) {
		std::cerr << "specify EITHER '" << ARG_F_BY_ID << "' OR '" << ARG_F_BY_NAME << "', not both!" << std::endl;
		return false;
	}
	return true;
}

HANDLE GetProcessById(int id);
HANDLE GetProcessByName(const std::string& str);

int main(int argc, char* argv[])
{
	InputParser input(argc, argv);
	if (!CheckParamsValid(input)) {
		return 1;
	}

	HANDLE hProc = INVALID_HANDLE_VALUE;
	if (input.cmdOptionExists(ARG_F_BY_ID)) {
		unsigned int pid = atoi(input.getCmdOption(ARG_F_BY_ID).c_str());
		hProc = GetProcessById(pid);
	}
	else if (input.cmdOptionExists(ARG_F_BY_NAME)) {
		hProc = GetProcessByName(input.getCmdOption(ARG_F_BY_NAME));
	}
	else {
		assert(false);
	}
	if (INVALID_HANDLE_VALUE == hProc) {
		std::wcerr << "process not found." << std::endl;
		return 1;
	}

	int interval = 1;
	if (input.cmdOptionExists(ARG_INTERVAL)) {
		interval = atoi(input.getCmdOption(ARG_INTERVAL).c_str());
	}
	ProcessWatcher procWatch(hProc, input.cmdOptionExists(ARG_VERBOSE), interval);
	return procWatch.Join(input.cmdOptionExists(ARG_WAIT_FOR_CHILDREN));
}

HANDLE GetProcessById(int id) {
	return OpenProcess(PROCESS_ALL_ACCESS, FALSE, id);
}

HANDLE GetProcessByName(const std::string& name) {
	HANDLE hProc = INVALID_HANDLE_VALUE;
	const char* pName = name.c_str();
	PROCESSENTRY32 entry;
	entry.dwSize = sizeof(PROCESSENTRY32);
	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
	if (TRUE == Process32First(snapshot, &entry))
	{
		while (TRUE == Process32Next(snapshot, &entry))
		{
			std::wstring wsName(entry.szExeFile);
			std::string csName(wsName.begin(), wsName.end());
			if (0 == _stricmp(csName.c_str(), pName))
			{
				hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, entry.th32ProcessID);
				break;
			}
		}
	}
	CloseHandle(snapshot);
	return hProc;
}