set serveroutput on
DECLARE
    lo_procs    async.tp_async_procs;
    ln_status   NUMBER;
    ld_start    TIMESTAMP; 
BEGIN
    lo_procs( 1).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 2).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 3).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 4).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 5).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 6).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 7).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 8).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs( 9).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    lo_procs(10).eval_code := 'mod(4,2);DBMS_LOCK.SLEEP(1)';
    --
    dbms_output.put_line('native execution ---------------------------------');
    ld_start := systimestamp;
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    ln_status := mod(4,2);DBMS_LOCK.SLEEP(1);
    dbms_output.put_line('    exit status  : ' || TO_CHAR( ln_status ));
    dbms_output.put_line('    elapsed time : ' || TO_CHAR( systimestamp - ld_start ));
    --
    dbms_output.put_line('series execution -----------------------------------');
    ld_start := systimestamp;
    async.series( io_async_procs => lo_procs , in_time_limit => 11, on_exit_status => ln_status );
    dbms_output.put_line('    exit status  : ' || TO_CHAR( ln_status ));
    dbms_output.put_line('    elapsed time : ' || TO_CHAR( systimestamp - ld_start ));
    --
    dbms_output.put_line('parallel execution ---------------------------------');
    ld_start := systimestamp;
    async.parallel_( io_async_procs => lo_procs , in_time_limit => 2, on_exit_status => ln_status );
    dbms_output.put_line('    exit status  : ' || TO_CHAR( ln_status ));
    dbms_output.put_line('    elapsed time : ' || TO_CHAR( systimestamp - ld_start ));
END;
