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
    cf_timeout              NUMBER          := ( 12 * 60 * 60 )   ; -- hhmiss
    cf_job_class            VARCHAR2(4000)  := 'DEFAULT_JOB_CLASS';
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
        (   cd              VARCHAR2(4000)
        );
    TYPE tp_promises        IS TABLE OF tp_promise  INDEX BY PLS_INTEGER;
    --
    TYPE tp_executor        IS RECORD
        (   eval_code       VARCHAR2(4000)  := '1'
        ,   resolution      VARCHAR2(4000)  := 'BEGIN :promise_status := %s; END;'
        );
    TYPE tp_executors       IS TABLE OF tp_executor INDEX BY PLS_INTEGER;
    --
    --**************************************************************************
    --  procedure
    --**************************************************************************
    ----------------------------------------------------------------------------
    --  NAME        : parallel
    --  DESCRIPTION : this procedure do the parallel execution.
    --  NOTES       :
    ----------------------------------------------------------------------------
    PROCEDURE parallel_
        (   io_executors    IN  async.tp_executors
        ,   in_time_limit   IN  NUMBER  := async.cf_timeout
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
        ,   in_time_limit   IN  NUMBER  := async.cf_timeout
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
        ,   iv_resolution   IN  VARCHAR2
        );
    --
    --==========================================================================
    --               Copyright (C) 2015 ken16 All Rights Reserved.
    --==========================================================================
END;
/