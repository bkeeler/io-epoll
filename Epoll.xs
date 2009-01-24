#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/epoll.h>

#include "const-c.inc"

MODULE = IO::Epoll		PACKAGE = IO::Epoll		

INCLUDE: const-xs.inc

int
epoll_create(size)
	int size

int
epoll_ctl(epfd,op,fd,events)
	int epfd
	int op
	int fd
	unsigned long events
CODE:
	struct epoll_event event;
	int ret;
	event.events = events;
	event.data.fd = fd;

	RETVAL = epoll_ctl(epfd, op, fd, &event);
OUTPUT:
	RETVAL

SV *
epoll_wait(epfd,maxevents,timeout)
	int epfd
	int maxevents
	int timeout
CODE:
	struct epoll_event *events;
	int ret, i;

	events = (struct epoll_event *)malloc(maxevents * sizeof(struct epoll_event));
	if (!events) {
		errno = ENOMEM;
		XSRETURN_UNDEF;
	}
	ret = epoll_wait(epfd, events, maxevents, timeout);
	if (ret < 0) {
		free(events);
		XSRETURN_UNDEF;
	} else {
		AV *results = (AV*)sv_2mortal((SV*)newAV());
		for (i = 0; i < ret; i++) {
			AV *ev = (AV*)sv_2mortal((SV*)newAV());
			av_push(ev, newSVnv(events[i].data.fd));
			av_push(ev, newSVnv(events[i].events));
			av_push(results, newRV((SV*) ev));
		}
		RETVAL = newRV((SV *)results);
		free(events);
	}
OUTPUT:
	RETVAL