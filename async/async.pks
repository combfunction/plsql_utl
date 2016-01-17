CREATE OR REPLACE PACKAGE async AUTHID DEFINER
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
    --  config
    --**************************************************************************
    cf_time_limit           NUMBER          := ( 12 * 60 * 60 )   ; -- hhmiss
    cf_job_class            VARCHAR2(30)    := 'DEFAULT_JOB_CLASS';
    cf_job_prefix           VARCHAR2(18)    := 'ASYNC#'; -- cf. DBMS_SCHEDULER.GENERATE_JOB_NAME
    --
    --**************************************************************************
    --  enum
    --**************************************************************************
    TYPE ed_promise_status  IS RECORD
        (   pending         NUMBER := -1
        ,   fulfilled       NUMBER :=  0
        ,   rejected        NUMBER := +1
        );
    --
    TYPE ed_exit_status     IS RECORD
        (   success         NUMBER :=  0
        ,   failure         NUMBER :=  1
        ,   timeout         NUMBER :=  2
        );
    --
    --**************************************************************************
    --  type
    --**************************************************************************
    TYPE tp_promise         IS RECORD
        (   cd              VARCHAR2(30)    --  job name and pipe name
        );
    TYPE tp_promises        IS TABLE OF tp_promise  INDEX BY SIMPLE_INTEGER;
    --
    TYPE tp_executor        IS RECORD
        (   eval_code       VARCHAR2(32767) := '1'
        ,   eval_block      VARCHAR2(32767) := 'BEGIN :promise_status := %s; END;'
        );
    TYPE tp_executors       IS TABLE OF tp_executor INDEX BY SIMPLE_INTEGER;
    --
    --**************************************************************************
    --  procedure
    --**************************************************************************
    ----------------------------------------------------------------------------
    --  NAME        : config
    --  DESCRIPTION : setter
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE config
        (   in_time_limit   IN  async.cf_time_limit%TYPE    := async.cf_time_limit
        ,   iv_job_class    IN  async.cf_job_class%TYPE     := async.cf_job_class
        ,   iv_job_prefix   IN  async.cf_job_prefix%TYPE    := async.cf_job_prefix
        );
    --
    ----------------------------------------------------------------------------
    --  NAME        : parallel
    --  DESCRIPTION : this procedure do the parallel execution.
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE parallel_
        (   io_executors    IN  async.tp_executors
        ,   in_time_limit   IN  NUMBER  := async.cf_time_limit
        ,   on_exit_status  OUT NUMBER
        );
    --
    ----------------------------------------------------------------------------
    --  NAME        : series
    --  DESCRIPTION : this procedure do the serial execution.
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE series
        (   io_executors    IN  async.tp_executors
        ,   in_time_limit   IN  NUMBER  := async.cf_time_limit
        ,   on_exit_status  OUT NUMBER
        );
    --
    ----------------------------------------------------------------------------
    --  NAME        : resolve
    --  DESCRIPTION : resolve promise
    --  NOTES       : this procedure is called by dbms_scheduler.
    ----------------------------------------------------------------------------
    PROCEDURE resolve
        (   iv_promise      IN  VARCHAR2
        ,   iv_eval_code    IN  VARCHAR2
        ,   iv_eval_block   IN  VARCHAR2
        );
    --
    ----------------------------------------------------------------------------
    --  NAME        : wait_for
    --  DESCRIPTION : wait for resolution of promise
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE wait_for
        (   io_promise      IN  async.tp_promise
        ,   in_time_limit   IN  NUMBER := async.cf_time_limit
        ,   on_exit_status  OUT NUMBER
        );
    --
    ----------------------------------------------------------------------------
    --  NAME        : promise_new
    --  DESCRIPTION : create and enqueue job
    --  NOTES       :
    ----------------------------------------------------------------------------
    FUNCTION promise_new
        (   io_executor     IN  async.tp_executor
        )   RETURN  async.tp_promise;
    --
    FUNCTION promise_new
        (   io_executor     IN  async.tp_executors
        )   RETURN  async.tp_promises;
    --
    ----------------------------------------------------------------------------
    --  NAME        : withdraw
    --  DESCRIPTION : cleanup, dequeue job if possibele
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE withdraw
        (   io_promise      IN  async.tp_promise
        );
    --
    PROCEDURE withdraw
        (   io_promise      IN  async.tp_promises
        );
    --
    --==========================================================================
    --               Copyright (C) 2016 ken16 All Rights Reserved.
    --==========================================================================
END;
/