#!/usr/bin/env bash

# settings
set_one_core=0
if_drop_cache=1

# constants
TRACEFS="/sys/kernel/tracing"
FIO_TEST_PATH="/tmp/fio_test"
N_CPU=$(nproc)

echo
echo "Script Settings:"
echo "set_one_core=${set_one_core}"
echo "if_drop_cache=${if_drop_cache}"
echo

# check root
[ $(whoami) != "root" ] && echo -e "Login as root first ... Exit\n" && exit

# make file
echo -n "Make file ... "
echo 0123456789 >test.txt
echo "Done"

# drop cache
if [ $if_drop_cache -eq 1 ]; then
	echo -n "Drop cache ... "
    echo 3 >/proc/sys/vm/drop_caches
    [ $? != 0 ] && echo -e "Failed: drop cache ... Exit\n" && exit
	echo "Done"
fi

# set ftrace
echo -n "Set ftrace ... "
echo 0 >$TRACEFS/tracing_on
############### Ftrace Options ###############
#echo nop >$TRACEFS/current_tracer
#echo function > $TRACEFS/current_tracer
echo function_graph >$TRACEFS/current_tracer
echo >$TRACEFS/set_ftrace_filter
echo 1000000 >$TRACEFS/buffer_size_kb
##############################################
echo "Done"

# compile
make -s

# disable CPU cores
if [ ${set_one_core} -eq 1 ]; then
    chcpu -d 1-$(($N_CPU - 1))
    [ $? != 0 ] && echo -e "Failed: disable CPU cores ... Exit\n" && exit
fi

# trace kernel
echo -n "Tracing ... "
echo 1 >$TRACEFS/tracing_on
echo "##### START TRACING" >$TRACEFS/trace_marker
taskset -c 10 ./open
echo "##### FINISH TRACING" >$TRACEFS/trace_marker
echo 0 >$TRACEFS/tracing_on
echo "Done"

# enable CPU cores
if [ ${set_one_core} -eq 1 ]; then
    chcpu -e 1-$(($N_CPU - 1))
    [ $? != 0 ] && echo -e "Failed: enable CPU cores ... Exit\n" && exit
fi

# move log
echo -n "Moving log ... "
# cat $TRACEFS/per_cpu/cpu20/trace_pipe >log.txt
cat $TRACEFS/per_cpu/cpu10/trace >log.txt
# cat $TRACEFS/trace_pipe >log.txt
echo "Done"

# clear ftrace
echo -n "Clear ftrace ... "
############### Ftrace Options ###############
echo 0 >$TRACEFS/tracing_on
echo nop >$TRACEFS/current_tracer
echo 0 >$TRACEFS/events/enable
#echo secondary_start_kernel >$TRACEFS/set_ftrace_filter
echo 0 >$TRACEFS/options/func_stack_trace
##############################################
echo "Done"

# clean up
echo -n "Cleaning up ... "
echo "Done"
make -s clean
rm test.txt

echo
echo "Trace Complete!"
exit

## [Backup] ####################################################################

