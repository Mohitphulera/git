#!/bin/sh

test_description='test git wire-protocol version 2'

TEST_NO_CREATE_REPO=1

. ./test-lib.sh

# Test protocol v2 with 'git://' transport
#
. "$TEST_DIRECTORY"/lib-git-daemon.sh
start_git_daemon --export-all --enable=receive-pack
daemon_parent=$GIT_DAEMON_DOCUMENT_ROOT_PATH/parent

test_expect_success 'create repo to be served by git-daemon' '
	git init "$daemon_parent" &&
	test_commit -C "$daemon_parent" one
'

test_expect_success 'list refs with git:// using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		ls-remote --symref "$GIT_DAEMON_URL/parent" >actual 2>log &&

	# Client requested to use protocol v2
	grep "git> .*\\\0\\\0version=2\\\0$" log &&
	# Server responded using protocol v2
	grep "git< version 2" log &&

	git ls-remote --symref "$GIT_DAEMON_URL/parent" >expect &&
	test_cmp actual expect
'

test_expect_success 'ref advertisment is filtered with ls-remote using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		ls-remote "$GIT_DAEMON_URL/parent" master 2>log &&

	grep "ref-pattern master" log &&
	! grep "refs/tags/" log
'

stop_git_daemon

# Test protocol v2 with 'file://' transport
#
test_expect_success 'create repo to be served by file:// transport' '
	git init file_parent &&
	test_commit -C file_parent one
'

test_expect_success 'list refs with file:// using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		ls-remote --symref "file://$(pwd)/file_parent" >actual 2>log &&

	# Server responded using protocol v2
	grep "git< version 2" log &&

	git ls-remote --symref "file://$(pwd)/file_parent" >expect &&
	test_cmp actual expect
'

test_expect_success 'ref advertisment is filtered with ls-remote using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		ls-remote "file://$(pwd)/file_parent" master 2>log &&

	grep "ref-pattern master" log &&
	! grep "refs/tags/" log
'

test_done
