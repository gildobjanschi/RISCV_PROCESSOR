/*
 Name        : syscalls.c
 Author      : Gil
 Version     :
 Copyright   :
 Description : system calls missing in order to link newlib.
 See https://github.com/xpack-dev-tools/riscv-newlib/tree/1e50b130fe1514a96eb4dc12f4a661d14f5cf6d4/libgloss.
 */
#include <sys/stat.h>
#include <errno.h>

/*
 * inbyte -- Read a byte TTY
 */
char inbyte() {
	char *ptr = (char *)0xc0000001;
	return *ptr;
}

/*
 * read  -- read bytes from the serial port. Ignore fd, since
 *          we only have stdin.
 */
int _read(int file, char *ptr, int len) {
	int i = 0;
	for (i = 0; i < len; i++) {
		*(ptr + i) = inbyte();
		if ((*(ptr + i) == '\n') || (*(ptr + i) == '\r')) {
			i++;
			break;
		}
	}

	return i;
}

/*
 * outbyte -- Write a byte to TTY
 */
void outbyte(char c) {
	// Write to STDOUT
	char *ptr = (char *)0xc0000000;
	*ptr = c;
}

/*
 * write -- write bytes to the serial port. Ignore fd, since
 *          stdout and stderr are the same. Since we have no filesystem,
 *          open will only return an error.
 */
int _write(int file, const char *ptr, int len) {

	for (int i = 0; i < len; i++) {
		if (*(ptr + i) == '\n') {
			outbyte('\r');
		}
		outbyte(*(ptr + i));
	}

	return len;
}

/*
 * close -- We don't need to do anything, but pretend we did.
 */
int _close(int file) {
	return 0;
}

/*
 * fstat -- Since we have no file system, we just return an error.
 */
int _fstat(int file, struct stat *st) {
	st->st_mode = S_IFCHR;
	st->st_blksize = 0;

	return 0;
}

/*
 * isatty -- returns 1 if connected to a terminal device,
 *           returns 0 if not. Since we're hooked up to a
 *           serial port, we'll say yes _AND return a 1.
 */
int _isatty(struct _reent *ptr, int fd) {
	// The file descriptor is a terminal
	return 1;
}

/*
 * lseek --  Since a serial port is non-seekable, we return an error.
 */
off_t _lseek(int fd, off_t offset, int whence) {
	errno = ESPIPE;
	return ((off_t) -1);
}
