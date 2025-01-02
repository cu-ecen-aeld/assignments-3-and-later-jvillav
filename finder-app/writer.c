#include <stdio.h>
#include <errno.h>
#include <syslog.h>


int main(int argc, char *argv[]){

	openlog("writer", LOG_PID | LOG_CONS, LOG_USER);
        syslog(LOG_DEBUG, "Starting Writer");

	if (argc != 3){
		syslog(LOG_ERR, "Usage: [/path/to/file] [file content]");
		closelog();
		return 1; // Returns 1 per specification, could return EINVAL (22 - Invalid argument)
	}

	// Give name to input arguments 
	const char *writefile = argv[1];
	const char *writestr = argv[2];

	syslog(LOG_DEBUG, "Writting %s to %s", writestr, writefile);
	FILE *file;

	file = fopen(writefile, "w");

	if (file == NULL){
		syslog(LOG_ERR, "Error while opening %s", writefile); // Log the error
		closelog();		// cleanup and exit
		fclose(file); 		//
		return 1; // Returns 1 per specification, could return the errno of the operation.
	}

	fprintf(file, "%s", writestr);
	
	closelog();
	fclose(file);

	return 0;
}
