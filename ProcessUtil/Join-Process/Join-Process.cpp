// Join-Process.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "InputParser.hpp"
#include "ProcessWatcher.h"
#include "ProcessUtils.h"

const char* ARG_F_BY_ID = "-pid";
const char* ARG_F_BY_NAME = "-name";
const char* ARG_INTERVAL = "-i";
const char* ARG_WAIT_FOR_CHILDREN = "-wait-for-children";
const char* ARG_VERBOSE = "-v";

void PrintUsage() {
	std::cout << "Join-Process.exe " << std::endl;
	std::cout << "usage: Join-Process "
		"[" << ARG_F_BY_ID << " <pid> "
		"| " << ARG_F_BY_NAME << " <process name>] "
		"[ " << ARG_INTERVAL << " <sec>] "
		"[" << ARG_WAIT_FOR_CHILDREN << "] "
		"[" << ARG_VERBOSE << "] "
		"[-help | -h]" << std::endl;

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
