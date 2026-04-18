       PROCESS SQL
      ******************************************************************
      *                                                                *
      * (C) Copyright IBM Corp. 2011, 2024                             *
      *                                                                *
      *                    ADD Pet Policy                              *
      *                                                                *
      *   To add full details of a pet insurance policy                *
      *                                                                *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LGAPPT01.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *
       DATA DIVISION.

       WORKING-STORAGE SECTION.

      *----------------------------------------------------------------*
      * Common defintions                                              *
      *----------------------------------------------------------------*
      * Run time (debug) infomation for this invocation
        01  WS-HEADER.
           03 WS-EYECATCHER            PIC X(16)
                                        VALUE 'LGAPPT01------WS'.
           03 WS-TRANSID               PIC X(4).
           03 WS-TERMID                PIC X(4).
           03 WS-TASKNUM               PIC 9(7).
           03 WS-FILLER                PIC X.
           03 WS-ADDR-DFHCOMMAREA      USAGE is POINTER.
           03 WS-CALEN                 PIC S9(4) COMP.

      * Variables for time/date processing
       01  ABS-TIME                    PIC S9(8) COMP VALUE +0.
       01  TIME1                       PIC X(8)  VALUE SPACES.
       01  DATE1                       PIC X(10) VALUE SPACES.

      * Error Message structure
       01  ERROR-MSG.
           03 EM-DATE                  PIC X(8)  VALUE SPACES.
           03 FILLER                   PIC X     VALUE SPACES.
           03 EM-TIME                  PIC X(6)  VALUE SPACES.
           03 FILLER                   PIC X(9)  VALUE ' LGAPPT01'.
           03 EM-VARIABLE.
             05 FILLER                 PIC X(6)  VALUE ' CNUM='.
             05 EM-CUSNUM              PIC X(10)  VALUE SPACES.
             05 FILLER                 PIC X(6)  VALUE ' PNUM='.
             05 EM-POLNUM              PIC X(10)  VALUE SPACES.
             05 EM-SQLREQ              PIC X(16) VALUE SPACES.
             05 FILLER                 PIC X(9)  VALUE ' SQLCODE='.
             05 EM-SQLRC               PIC +9(5) USAGE DISPLAY.

       01  CA-ERROR-MSG.
           03 FILLER                   PIC X(9)  VALUE 'COMMAREA='.
           03 CA-DATA                  PIC X(90) VALUE SPACES.
      *----------------------------------------------------------------*

      *----------------------------------------------------------------*
      * Definitions required for data manipulation                     *
      *----------------------------------------------------------------*
      * Fields to be used to check that commarea is correct length
       01  WS-COMMAREA-LENGTHS.
           03 WS-CA-HEADER-LEN         PIC S9(4) COMP VALUE +28.
           03 WS-REQUIRED-CA-LEN       PIC S9(4)      VALUE +0.

      *----------------------------------------------------------------*

      *----------------------------------------------------------------*
      * Definitions required by SQL statement                          *
      *   DB2 datatypes to COBOL equivalents                           *
      *     SMALLINT    :   PIC S9(4) COMP                             *
      *     INTEGER     :   PIC S9(9) COMP                             *
      *     DATE        :   PIC X(10)                                  *
      *     TIMESTAMP   :   PIC X(26)                                  *
      *----------------------------------------------------------------*
      * Host variables for input to DB2 integer types
       01 DB2-IN-INTEGERS.
           03 DB2-CUSTOMERNUM-INT      PIC S9(9) COMP.
           03 DB2-BROKERID-INT         PIC S9(9) COMP.
           03 DB2-PAYMENT-INT          PIC S9(9) COMP.
           03 DB2-P-VALUE-INT          PIC S9(9) COMP.
           03 DB2-P-PREMIUM-INT        PIC S9(9) COMP.

       01 DB2-OUT-INTEGERS.
           03 DB2-POLICYNUM-INT        PIC S9(9) COMP VALUE +0.
      *----------------------------------------------------------------*
       01  LGAPVS01                    PIC X(8)  VALUE 'LGAPVS01'.
      *----------------------------------------------------------------*
      *    DB2 CONTROL
      *----------------------------------------------------------------*
      *    Include copybook for definition of policy details
           EXEC SQL
             INCLUDE LGPOLICY
           END-EXEC.
      * SQLCA DB2 communications area
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.


      ******************************************************************
      *    L I N K A G E     S E C T I O N
      ******************************************************************
       LINKAGE SECTION.

       01  DFHCOMMAREA.
           EXEC SQL
             INCLUDE LGCMAREA
           END-EXEC.


      ******************************************************************
      *    P R O C E D U R E S
      ******************************************************************
       PROCEDURE DIVISION.

      *----------------------------------------------------------------*
       MAINLINE SECTION.

      * initialize working storage variables
           INITIALIZE WS-HEADER.
      * set up general variable
           MOVE EIBTRNID TO WS-TRANSID.
           MOVE EIBTRMID TO WS-TERMID.
           MOVE EIBTASKN TO WS-TASKNUM.
           MOVE EIBCALEN TO WS-CALEN.
      *----------------------------------------------------------------*

      * initialize DB2 host variables
           INITIALIZE DB2-IN-INTEGERS.
           INITIALIZE DB2-OUT-INTEGERS.

      *----------------------------------------------------------------*
      * Check commarea and obtain required details                     *
      *----------------------------------------------------------------*
      * If NO commarea received issue an ABEND
           IF EIBCALEN IS EQUAL TO ZERO
               MOVE ' NO COMMAREA RECEIVED' TO EM-VARIABLE
               PERFORM WRITE-ERROR-MESSAGE
               EXEC CICS ABEND ABCODE('LGCA') NODUMP END-EXEC
           END-IF

      * initialize commarea return code to zero
           MOVE '00' TO CA-RETURN-CODE
           SET WS-ADDR-DFHCOMMAREA TO ADDRESS OF DFHCOMMAREA.

      * Convert commarea customer num to DB2 integer format
           MOVE CA-CUSTOMER-NUM TO DB2-CUSTOMERNUM-INT
      * and save in error msg field incase required
           MOVE CA-CUSTOMER-NUM TO EM-CUSNUM

      * Check commarea length
           ADD WS-CA-HEADER-LEN  TO WS-REQUIRED-CA-LEN
           ADD WS-FULL-PET-LEN   TO WS-REQUIRED-CA-LEN
           MOVE 'P' TO DB2-POLICYTYPE

      *    if less set error return code and return to caller
           IF EIBCALEN IS LESS THAN WS-REQUIRED-CA-LEN
             MOVE '98' TO CA-RETURN-CODE
             EXEC CICS RETURN END-EXEC
           END-IF

      *----------------------------------------------------------------*
      *    Perform the INSERTs against appropriate tables              *
      *----------------------------------------------------------------*
      *    Call procedure to Insert row in policy table
           PERFORM INSERT-POLICY

      *    Call procedure to insert row to pet policy table
           PERFORM INSERT-PET

           EXEC CICS Link Program(LGAPVS01)
                Commarea(DFHCOMMAREA)
              LENGTH(32500)
           END-EXEC.

      * Return to caller
           EXEC CICS RETURN END-EXEC.

       MAINLINE-EXIT.
           EXIT.
      *----------------------------------------------------------------*


      *================================================================*
      *  Issue INSERT on Policy table using values passed in commarea  *
      * set the timestamp and allow DB2 to allocate a policy number.   *
      *================================================================*
       INSERT-POLICY.

      *    Move numeric fields to integer format
           MOVE CA-BROKERID TO DB2-BROKERID-INT
           MOVE CA-PAYMENT TO DB2-PAYMENT-INT

           MOVE ' INSERT POLICY' TO EM-SQLREQ
           EXEC SQL
             INSERT INTO POLICY
                       ( POLICYNUMBER,
                         CUSTOMERNUMBER,
                         ISSUEDATE,
                         EXPIRYDATE,
                         POLICYTYPE,
                         LASTCHANGED,
                         BROKERID,
                         BROKERSREFERENCE,
                         PAYMENT           )
                VALUES ( DEFAULT,
                         :DB2-CUSTOMERNUM-INT,
                         :CA-ISSUE-DATE,
                         :CA-EXPIRY-DATE,
                         :DB2-POLICYTYPE,
                         CURRENT TIMESTAMP,
                         :DB2-BROKERID-INT,
                         :CA-BROKERSREF,
                         :DB2-PAYMENT-INT      )
           END-EXEC

           Evaluate SQLCODE

             When 0
               MOVE '00' TO CA-RETURN-CODE

             When -530
               MOVE '70' TO CA-RETURN-CODE
               PERFORM WRITE-ERROR-MESSAGE
               EXEC CICS RETURN END-EXEC

             When Other
               MOVE '90' TO CA-RETURN-CODE
               PERFORM WRITE-ERROR-MESSAGE
               EXEC CICS RETURN END-EXEC

           END-Evaluate.

      *    get value of assigned policy number
           EXEC SQL
             SET :DB2-POLICYNUM-INT = IDENTITY_VAL_LOCAL()
           END-EXEC
           MOVE DB2-POLICYNUM-INT TO CA-POLICY-NUM
      *    and save in error msg field incase required
           MOVE CA-POLICY-NUM TO EM-POLNUM

      *    get value of assigned Timestamp
           EXEC SQL
             SELECT LASTCHANGED
               INTO :CA-LASTCHANGED
               FROM POLICY
               WHERE POLICYNUMBER = :DB2-POLICYNUM-INT
           END-EXEC.
           EXIT.

      *================================================================*
      * Issue INSERT on pet table using values passed in commarea      *
      *================================================================*
       INSERT-PET.

      *    Move numeric fields to integer format
           MOVE CA-P-VALUE    TO DB2-P-VALUE-INT
           MOVE CA-P-PREMIUM  TO DB2-P-PREMIUM-INT

           MOVE ' INSERT PET   ' TO EM-SQLREQ
           EXEC SQL
             INSERT INTO PET
                       ( POLICYNUMBER,
                         PETNAME,
                         PETTYPE,
                         PETBREED,
                         DATEOFBIRTH,
                         VALUE,
                         PREMIUM,
                         VETNAME,
                         VETPHONE,
                         PREEXISTING   )
                VALUES ( :DB2-POLICYNUM-INT,
                         :CA-P-PETNAME,
                         :CA-P-PETTYPE,
                         :CA-P-PETBREED,
                         :CA-P-DATEOFBIRTH,
                         :DB2-P-VALUE-INT,
                         :DB2-P-PREMIUM-INT,
                         :CA-P-VETNAME,
                         :CA-P-VETPHONE,
                         :CA-P-PREEXISTING    )
           END-EXEC

           IF SQLCODE NOT EQUAL 0
             MOVE '90' TO CA-RETURN-CODE
             PERFORM WRITE-ERROR-MESSAGE
      *      Issue Abend to cause backout of update to Policy table
             EXEC CICS ABEND ABCODE('LGSQ') NODUMP END-EXEC
             EXEC CICS RETURN END-EXEC
           END-IF.

           EXIT.

      *================================================================*
      * Procedure to write error message to Queues                     *
      *   message will include Date, Time, Program Name, Customer      *
      *   Number, Policy Number and SQLCODE.                           *
      *================================================================*
       WRITE-ERROR-MESSAGE.
      * Save SQLCODE in message
           MOVE SQLCODE TO EM-SQLRC
      * Obtain and format current time and date
           EXEC CICS ASKTIME ABSTIME(ABS-TIME)
           END-EXEC
           EXEC CICS FORMATTIME ABSTIME(ABS-TIME)
                     MMDDYYYY(DATE1)
                     TIME(TIME1)
           END-EXEC
           MOVE DATE1 TO EM-DATE
           MOVE TIME1 TO EM-TIME
      * Write output message to TDQ
           EXEC CICS LINK PROGRAM('LGSTSQ')
                     COMMAREA(ERROR-MSG)
                     LENGTH(LENGTH OF ERROR-MSG)
           END-EXEC.
      * Write 90 bytes or as much as we have of commarea to TDQ
           IF EIBCALEN > 0 THEN
             IF EIBCALEN < 91 THEN
               MOVE DFHCOMMAREA(1:EIBCALEN) TO CA-DATA
               EXEC CICS LINK PROGRAM('LGSTSQ')
                         COMMAREA(CA-ERROR-MSG)
                         LENGTH(LENGTH OF CA-ERROR-MSG)
               END-EXEC
             ELSE
               MOVE DFHCOMMAREA(1:90) TO CA-DATA
               EXEC CICS LINK PROGRAM('LGSTSQ')
                         COMMAREA(CA-ERROR-MSG)
                         LENGTH(LENGTH OF CA-ERROR-MSG)
               END-EXEC
             END-IF
           END-IF.
           EXIT.
