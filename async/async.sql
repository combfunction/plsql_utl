--CREATE TABLE "ASYNC_TEST"
--    (   "CREATE_AT" VARCHAR2(30)
--    ,   "VALUE_"    NUMBER
--    );
--
set serveroutput on
DECLARE
    lo_procs    async.tp_executors;
    ln_status   NUMBER;
    ld_start    TIMESTAMP; 
BEGIN
    async.config
        (   in_time_limit  => 11
        ,   iv_job_prefix  => 'ASYNC_TEST#'
        );
    lo_procs( 1).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  1 )|';
    lo_procs( 2).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  2 )|';
    lo_procs( 3).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  3 )|';
    lo_procs( 4).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  4 )|';
    lo_procs( 5).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  5 )|';
    lo_procs( 6).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  6 )|';
    lo_procs( 7).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  7 )|';
    lo_procs( 8).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  8 )|';
    lo_procs( 9).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ),  9 )|';
    lo_procs(10).eval_code := q'|0;DBMS_LOCK.SLEEP(1);insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' ), 10 )|';
    --
    dbms_output.put_line('series execution -----------------------------------');
    ld_start := systimestamp;
    async.series( io_executors => lo_procs , in_time_limit => 11, on_exit_status => ln_status );
    dbms_output.put_line('    exit status  : ' || TO_CHAR( ln_status ));
    dbms_output.put_line('    elapsed time : ' || TO_CHAR( systimestamp - ld_start ));
    --
    dbms_output.put_line('parallel execution ---------------------------------');
    ld_start := systimestamp;
    async.parallel_( io_executors => lo_procs , in_time_limit => 2, on_exit_status => ln_status );
    dbms_output.put_line('    exit status  : ' || TO_CHAR( ln_status ));
    dbms_output.put_line('    elapsed time : ' || TO_CHAR( systimestamp - ld_start ));
END;
