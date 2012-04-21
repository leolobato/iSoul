#!/bin/sh

BACKENDS="EVPORT KQUEUE EPOLL DEVPOLL POLL SELECT WIN32"
TESTS="test-eof test-weof test-time test-changelist test-fdleak"
FAILED=no
TEST_OUTPUT_FILE=${TEST_OUTPUT_FILE:-/dev/null}

# /bin/echo is a little more likely to support -n than sh's builtin echo,
# printf is even more likely
if test "`printf %s hello 2>&1`" = "hello"
then
	ECHO_N="printf %s"
else
	if test -x /bin/echo
	then
		ECHO_N="/bin/echo -n"
	else
		ECHO_N="echo -n"
	fi
fi

if test "$TEST_OUTPUT_FILE" != "/dev/null"
then
	touch "$TEST_OUTPUT_FILE" || exit 1
fi

TEST_DIR=.
TEST_SRC_DIR=.

T=`echo "$0" | sed -e 's/test.sh$//'`
if test -x "$T/test-init"
then
	TEST_DIR="$T"
fi
if test -e "$T/check-dumpevents.py"
then
	TEST_SRC_DIR="$T"
fi

setup () {
	for i in $BACKENDS; do
		eval "EVENT_NO$i=yes; export EVENT_NO$i"
	done
	unset EVENT_EPOLL_USE_CHANGELIST
}

announce () {
	echo "$@"
	echo "$@" >>"$TEST_OUTPUT_FILE"
}

announce_n () {
	$ECHO_N "$@"
	echo "$@" >>"$TEST_OUTPUT_FILE"
}


run_tests () {
	if $TEST_DIR/test-init 2>>"$TEST_OUTPUT_FILE" ;
	then
		true
	else
		announce Skipping test
		return
	fi
	for i in $TESTS; do
		announce_n " $i: "
		if $TEST_DIR/$i >>"$TEST_OUTPUT_FILE" ;
		then
			announce OKAY ;
		else
			announce FAILED ;
			FAILED=yes
		fi
	done
	announce_n " test-dumpevents: "
	if python -c 'import sys; assert(sys.version_info >= (2, 4))' 2>/dev/null; then
	    if $TEST_DIR/test-dumpevents | python $TEST_SRC_DIR/check-dumpevents.py >> "$TEST_OUTPUT_FILE" ;
	    then
	        announce OKAY ;
	    else
	        announce FAILED ;
	    fi
	else
	    # no python
	    if $TEST_DIR/test-dumpevents >/dev/null; then
	        announce "OKAY (output not checked)" ;
	    else
	        announce "FAILED (output not checked)" ;
	    fi
	fi
	test -x $TEST_DIR/regress || return
	announce_n " regress: "
	if test "$TEST_OUTPUT_FILE" = "/dev/null" ;
	then
		$TEST_DIR/regress --quiet
	else
		$TEST_DIR/regress >>"$TEST_OUTPUT_FILE"
	fi
	if test "$?" = "0" ;
	then
		announce OKAY ;
	else
		announce FAILED ;
		FAILED=yes
	fi
}

do_test() {
	setup
	announce "$1 $2"
	unset EVENT_NO$1
	if test "$2" = "(changelist)" ; then
	    EVENT_EPOLL_USE_CHANGELIST=yes; export EVENT_EPOLL_USE_CHANGELIST
        fi
	run_tests
}

announce "Running tests:"

for i in $BACKENDS; do
	do_test $i
done
do_test EPOLL "(changelist)"

if test "$FAILED" = "yes"; then
	exit 1
fi