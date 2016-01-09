CREATE OR REPLACE PACKAGE BODY async
    ----------------------------------------------------------------------------
    --  NAME        : async
    --  DESCRIPTION : this package provides the asynchronous execution.
    --  REQUIRE     : dbms_scheduler, dbms_pipe
    ----------------------------------------------------------------------------
IS
    --**************************************************************************
    --  pragma
    --**************************************************************************
    PRAGMA SERIALLY_REUSABLE;
    --
    --**************************************************************************
    --  forward declaration
    --**************************************************************************
    PROCEDURE wait_for
        (   io_promise      IN  async.tp_promise
        ,   in_time_limit   IN  NUMBER := async.cf_timeout
        ,   on_exit_status  OUT NUMBER
        );
    --
    FUNCTION promise_new
        (   io_executor     IN  async.tp_executor
        )   RETURN  async.tp_promise;
    FUNCTION promise_new
        (   io_executor     IN  async.tp_executors
        )   RETURN  async.tp_promises;
    --
    PROCEDURE withdraw
        (   io_promise      IN  async.tp_promise
        );
    PROCEDURE withdraw
        (   io_promise      IN  async.tp_promises
        );
    --
    --**************************************************************************
    --  public procedure
    --**************************************************************************
    ----------------------------------------------------------------------------
    --  NAME        : parallel_
    --  DESCRIPTION : this procedure do the parallel execution.
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE parallel_
        (   io_executors    IN  async.tp_executors
        ,   in_time_limit   IN  NUMBER  := async.cf_timeout
        ,   on_exit_status  OUT NUMBER
        )
    IS
        en_exit_status      async.ed_exit_status;
        --
        ln_exit_status      NUMBER := en_exit_status.success;
        ln_start_time       NUMBER;
        ln_end_time         NUMBER;
        ln_elapsed_time     NUMBER := 0;
        lo_promises         async.tp_promises;
        lo_promise          async.tp_promise ;
        --
    BEGIN
        --  create promise ( i.e. enqueue job )
        lo_promises := promise_new( io_executor => io_executors );
        --
        FOR i IN REVERSE 1 .. lo_promises.COUNT LOOP
            --  pop on promise
            lo_promise := lo_promises(i);
            lo_promises.DELETE(i);
            --
            --  wait for promise
            ln_start_time   := DBMS_UTILITY.GET_TIME;
            --
            wait_for
                (   io_promise      => lo_promise
                ,   in_time_limit   => in_time_limit - ln_elapsed_time
                ,   on_exit_status  => ln_exit_status
                );
            EXIT WHEN ln_exit_status <> en_exit_status.success;
            --
            ln_end_time     := DBMS_UTILITY.GET_TIME;
            --
            --  counting elapsed time
            ln_elapsed_time :=
            ln_elapsed_time  + ( ln_end_time - ln_start_time ) / 100;
            --
        END LOOP;
        --
        --  cleanup rest of promise
        IF lo_promises.COUNT > 0 THEN
            withdraw( io_promise => lo_promises );
            --
        END IF;
        --
        on_exit_status  := ln_exit_status;
        --
    EXCEPTION
        WHEN OTHERS THEN
            --  cleanup rest of promise
            withdraw( io_promise => lo_promises );
            on_exit_status := en_exit_status.failure;
    END;
    --
    ----------------------------------------------------------------------------
    --  NAME        : series
    --  DESCRIPTION : this procedure do the serial execution.
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE series
        (   io_executors    IN  async.tp_executors
        ,   in_time_limit   IN  NUMBER  := async.cf_timeout
        ,   on_exit_status  OUT NUMBER
        )
    IS
        en_exit_status      async.ed_exit_status;
        --
        ln_exit_status      NUMBER := en_exit_status.success;
        ln_start_time       NUMBER;
        ln_end_time         NUMBER;
        ln_elapsed_time     NUMBER := 0;
        lo_promise          async.tp_promise;
        --
    BEGIN
        FOR i IN 1 .. io_executors.COUNT LOOP
            --  create promise ( i.e. enqueue job )
            lo_promise  := promise_new( io_executor => io_executors(i) );
            --
            --  wait for promise
            ln_start_time   := DBMS_UTILITY.GET_TIME;
            --
            wait_for
                (   io_promise      => lo_promise
                ,   in_time_limit   => in_time_limit - ln_elapsed_time
                ,   on_exit_status  => ln_exit_status
                );
            EXIT WHEN ln_exit_status <> en_exit_status.success;
            --
            ln_end_time     := DBMS_UTILITY.GET_TIME;
            --
            --  counting elapsed time
            ln_elapsed_time :=
            ln_elapsed_time  + ( ln_end_time - ln_start_time ) / 100;
            --
        END LOOP;
        --
        on_exit_status := ln_exit_status;
        --
    EXCEPTION
        WHEN OTHERS THEN
            on_exit_status := en_exit_status.failure;
    END;
    --
    ----------------------------------------------------------------------------
    --  NAME        : resolve
    --  DESCRIPTION : resolve promise i.e. execute proc
    --  NOTES       : this procedure is called by dbms_scheduler.
    ----------------------------------------------------------------------------
    PROCEDURE resolve
        (   iv_promise      IN  VARCHAR2
        ,   iv_eval_code    IN  VARCHAR2
        ,   iv_resolution   IN  VARCHAR2
        )
    IS
        ln_promise_status   NUMBER;
        --
    BEGIN
        --  resolve promise
        EXECUTE IMMEDIATE UTL_LMS.FORMAT_MESSAGE( iv_resolution, iv_eval_code )
        USING OUT ln_promise_status;
        --
        --  set promise status
        DBMS_PIPE.PACK_MESSAGE( ln_promise_status );
        IF DBMS_PIPE.SEND_MESSAGE( iv_promise, async.cf_timeout ) <> 0 THEN
            NULL;
            --
        END IF;
        --
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
    --
    --**************************************************************************
    --  private procedure
    --**************************************************************************
    ----------------------------------------------------------------------------
    --  NAME        : wait_for
    --  DESCRIPTION : wait for resolution of promise
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE wait_for
        (   io_promise      IN  async.tp_promise
        ,   in_time_limit   IN  NUMBER := async.cf_timeout
        ,   on_exit_status  OUT NUMBER
        )
    IS
        en_promise_status   async.ed_promise_status;
        en_exit_status      async.ed_exit_status;
        --
        ln_promise_status   NUMBER  := NULL;
        ln_time_limit       NUMBER  := GREATEST( CEIL( in_time_limit ), 0 );
        --
    BEGIN
        --  wait for promise
        IF DBMS_PIPE.RECEIVE_MESSAGE( io_promise.cd, ln_time_limit ) = 0 THEN
            --  get promise status ( fulfilled or rejected )
            DBMS_PIPE.UNPACK_MESSAGE( ln_promise_status );
            DBMS_PIPE.PURGE( io_promise.cd );
            --
        ELSE
            --  cleanup for timeout or interrupte
            withdraw( io_promise => io_promise );
            --
        END IF;
        --
        on_exit_status  :=
            CASE ln_promise_status
            WHEN en_promise_status.fulfilled THEN en_exit_status.success
            WHEN en_promise_status.rejected  THEN en_exit_status.failure
            ELSE                                  en_exit_status.timeout
            END;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
    --
    ----------------------------------------------------------------------------
    --  NAME        : promise_new
    --  DESCRIPTION : create and enqueue job
    --  NOTES       :
    ----------------------------------------------------------------------------
    FUNCTION promise_new
        (   io_executor     IN  async.tp_executor
        )   RETURN  async.tp_promise
    IS
        lo_promise          async.tp_promise;
        lv_promise_prefix   VARCHAR2(18);   --  GENERATE_JOB_NAME expect that size is less than 19
        lo_job_args         JOBARG_ARRAY;
        lo_job_def          JOB_DEFINITION;
        --
    BEGIN
        --  set job name
        lv_promise_prefix   := 'Z' || TO_CHAR( SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF2' ) || '#';
        lo_promise.cd       := DBMS_SCHEDULER.GENERATE_JOB_NAME( lv_promise_prefix );
        --  set job arguments
        lo_job_args := JOBARG_ARRAY
            (   JOBARG( ARG_POSITION => 1, ARG_VALUE => lo_promise.cd           )
            ,   JOBARG( ARG_POSITION => 2, ARG_VALUE => io_executor.eval_code   )
            ,   JOBARG( ARG_POSITION => 3, ARG_VALUE => io_executor.resolution  )
            );
        --  set job definition
        lo_job_def  := JOB_DEFINITION
            (   JOB_NAME            => lo_promise.cd
            ,   JOB_CLASS           => async.cf_job_class
            ,   JOB_TYPE            => 'STORED_PROCEDURE'
            ,   JOB_ACTION          => UPPER( 'async.resolve' )
            ,   ARGUMENTS           => lo_job_args
            ,   NUMBER_OF_ARGUMENTS => lo_job_args.COUNT
            ,   MAX_RUNS            => 1
            ,   ENABLED             => TRUE
            );
        --  create and enqueue job
        DBMS_SCHEDULER.CREATE_JOBS( JOB_DEFINITION_ARRAY( lo_job_def ) );
        --
        RETURN lo_promise;
        --
    EXCEPTION
        WHEN OTHERS THEN
            withdraw( io_promise => lo_promise );
            RAISE;
    END;
    --
    ----------------------------------------------------------------------------
    --  NAME        : promise_new
    --  DESCRIPTION : simple wrapper
    --  NOTES       :
    ----------------------------------------------------------------------------
    FUNCTION promise_new
        (   io_executor     IN  async.tp_executors
        )   RETURN  async.tp_promises
    IS
        lo_promises         async.tp_promises;
        --
    BEGIN
        FOR i IN 1 .. io_executor.COUNT LOOP
            lo_promises(i)  := promise_new( io_executor => io_executor(i) );
            --
        END LOOP;
        --
        RETURN lo_promises;
        --
    EXCEPTION
        WHEN OTHERS THEN
            withdraw( io_promise => lo_promises );
            RAISE;
    END;
    --
    ----------------------------------------------------------------------------
    --  NAME        : withdraw
    --  DESCRIPTION : cleanup, dequeue job if possibele
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE withdraw
        (   io_promise      IN  async.tp_promise
        )
    IS
    BEGIN
        --  if promise was already resolved
        IF DBMS_PIPE.RECEIVE_MESSAGE( io_promise.cd, 0 ) = 0 THEN
            DBMS_PIPE.PURGE( io_promise.cd );
            RETURN;
            --
        END IF;
        --
        --  cleanup at any rate ( eafp style )
        DECLARE
            ex_already_dropped  EXCEPTION;
            PRAGMA EXCEPTION_INIT( ex_already_dropped, -27362 );
            --
        BEGIN
            DBMS_SCHEDULER.DROP_JOB
                (   JOB_NAME            => io_promise.cd
                ,   FORCE               => TRUE
                ,   COMMIT_SEMANTICS    => 'ABSORB_ERRORS'
                );
            --
        EXCEPTION
            WHEN ex_already_dropped THEN
                NULL;   --  maybe auto_drop and drop_job collnme
        END;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
    --
    ----------------------------------------------------------------------------
    --  NAME        : withdraw
    --  DESCRIPTION : simple wrapper
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE withdraw
        (   io_promise      IN  async.tp_promises
        )
    IS
    BEGIN
        FOR i IN 1 .. io_promise.COUNT LOOP
            withdraw( io_promise => io_promise(i) );
            --
        END LOOP;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
    --
    --==========================================================================
    --               Copyright (C) 2015 ken16 All Rights Reserved.
    --==========================================================================
END;
/
