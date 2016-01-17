--CREATE TABLE "ASYNC_TEST"
--    (   "CREATE_AT" VARCHAR2(30)
--    ,   "VALUE_"    NUMBER
--    );
--
--create or replace function ASYNC_TEST_1
--    (   in_status       number
--    ,   in_sleep_time   number
--    ,   in_set_value    number
--    )   RETURN number
--is
--    lv_stamp ASYNC_TEST.CREATE_AT%TYPE;
--begin
--    DBMS_LOCK.SLEEP(in_sleep_time);
--    lv_stamp := TO_CHAR( SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS FF3' );
--    insert into ASYNC_TEST ( CREATE_AT, VALUE_ ) values ( lv_stamp,  in_set_value );
--    if in_status = 0 then
--        commit;
--    else
--        ROLLBACK;
--    end if;
--    
--    RETURN in_status;
--end;
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
    lo_procs( 1).eval_code := q'|ASYNC_TEST_1(0,1, 1)|';
    lo_procs( 2).eval_code := q'|ASYNC_TEST_1(0,1, 2)|';
    lo_procs( 3).eval_code := q'|ASYNC_TEST_1(0,1, 3)|';
    lo_procs( 4).eval_code := q'|ASYNC_TEST_1(0,1, 4)|';
    lo_procs( 5).eval_code := q'|ASYNC_TEST_1(1,1, 5)|';
    lo_procs( 6).eval_code := q'|ASYNC_TEST_1(0,1, 6)|';
    lo_procs( 7).eval_code := q'|ASYNC_TEST_1(0,1, 7)|';
    lo_procs( 8).eval_code := q'|ASYNC_TEST_1(0,1, 8)|';
    lo_procs( 9).eval_code := q'|ASYNC_TEST_1(0,1, 9)|';
    lo_procs(10).eval_code := q'|ASYNC_TEST_1(0,1,10)|';
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
