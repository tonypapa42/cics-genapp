      ******************************************************************
      *                                                                *
      * (C) Copyright IBM Corp. 2011, 2026                             *
      *                                                                *
      *                    Pet Policy Menu                             *
      *                                                                *
      * Menu for Pet Policy Transactions                               *
      *                                                                *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LGTESTP6.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       77 MSGEND                       PIC X(24) VALUE
                                        'Transaction ended      '.

       COPY SSMAP.
       01 COMM-AREA.
       COPY LGCMAREA.

      *----------------------------------------------------------------*
      *****************************************************************
       PROCEDURE DIVISION.

      *---------------------------------------------------------------*
       MAINLINE SECTION.

           IF EIBCALEN > 0
              GO TO A-GAIN.

           Initialize SSMAPP6I.
           Initialize SSMAPP6O.
           Initialize COMM-AREA.
           MOVE '0000000000'   To ENP6CNOO.
           MOVE '0000000000'   To ENP6PNOO.
           MOVE '00'           To ENP6AGEO.
           MOVE '00000000'     To ENP6VALO.
           MOVE '000000'       To ENP6PREO.

      * Display Main Menu
           EXEC CICS SEND MAP ('SSMAPP6')
                     MAPSET ('SSMAP')
                     ERASE
                     END-EXEC.

       A-GAIN.

           EXEC CICS HANDLE AID
                     CLEAR(CLEARIT)
                     PF3(ENDIT) END-EXEC.
           EXEC CICS HANDLE CONDITION
                     MAPFAIL(ENDIT)
                     END-EXEC.

           EXEC CICS RECEIVE MAP('SSMAPP6')
                     INTO(SSMAPP6I)
                     MAPSET('SSMAP') END-EXEC.


           EVALUATE ENP6OPTO

             WHEN '1'
                 Move '01IPET'   To CA-REQUEST-ID
                 Move ENP6CNOO   To CA-CUSTOMER-NUM
                 Move ENP6PNOO   To CA-POLICY-NUM
                 EXEC CICS LINK PROGRAM('LGIPOL01')
                           COMMAREA(COMM-AREA)
                           LENGTH(32500)
                 END-EXEC
                 IF CA-RETURN-CODE > 0
                   GO TO NO-DATA
                 END-IF

                 Move CA-ISSUE-DATE      To  ENP6IDAI
                 Move CA-EXPIRY-DATE     To  ENP6EDAI
                 Move CA-P-PETTYPE       To  ENP6PTYI
                 Move CA-P-BREED         To  ENP6BRDI
                 Move CA-P-NAME          To  ENP6NAMI
                 Move CA-P-AGE           To  ENP6AGEI
                 Move CA-P-VACCINATED    To  ENP6VACI
                 Move CA-P-CHIPID        To  ENP6CHPI
                 Move CA-P-INSUREDVALUE  To  ENP6VALI
                 Move CA-P-PREMIUM       To  ENP6PREI
                 EXEC CICS SEND MAP ('SSMAPP6')
                           FROM(SSMAPP6O)
                           MAPSET ('SSMAP')
                 END-EXEC
                 GO TO ENDIT-STARTIT

             WHEN '2'
                 Move '01APET'          To CA-REQUEST-ID
                 Move ENP6CNOI          To CA-CUSTOMER-NUM
                 Move 0                 To CA-PAYMENT
                 Move 0                 To CA-BROKERID
                 Move '        '        To CA-BROKERSREF
                 Move ENP6IDAI          To CA-ISSUE-DATE
                 Move ENP6EDAI          To CA-EXPIRY-DATE
                 Move ENP6PTYI          To CA-P-PETTYPE
                 Move ENP6BRDI          To CA-P-BREED
                 Move ENP6NAMI          To CA-P-NAME
                 Move ENP6AGEI          To CA-P-AGE
                 Move ENP6VACI          To CA-P-VACCINATED
                 Move ENP6CHPI          To CA-P-CHIPID
                 Move ENP6VALI          To CA-P-INSUREDVALUE
                 Move ENP6PREI          To CA-P-PREMIUM
                 EXEC CICS LINK PROGRAM('LGAPOL01')
                           COMMAREA(COMM-AREA)
                           LENGTH(32500)
                 END-EXEC
                 IF CA-RETURN-CODE > 0
                   Exec CICS Syncpoint Rollback End-Exec
                   GO TO NO-ADD
                 END-IF

                 Move CA-CUSTOMER-NUM To ENP6CNOI
                 Move CA-POLICY-NUM   To ENP6PNOI
                 Move ' '             To ENP6OPTI
                 Move 'New Pet Policy Inserted'
                   To  ERP6FLDO
                 EXEC CICS SEND MAP ('SSMAPP6')
                           FROM(SSMAPP6O)
                           MAPSET ('SSMAP')
                 END-EXEC
                 GO TO ENDIT-STARTIT

             WHEN '3'
                 Move '01DPET'   To CA-REQUEST-ID
                 Move ENP6CNOO   To CA-CUSTOMER-NUM
                 Move ENP6PNOO   To CA-POLICY-NUM
                 EXEC CICS LINK PROGRAM('LGDPOL01')
                           COMMAREA(COMM-AREA)
                           LENGTH(32500)
                 END-EXEC
                 IF CA-RETURN-CODE > 0
                   Exec CICS Syncpoint Rollback End-Exec
                   GO TO NO-DELETE
                 END-IF

                 Move Spaces             To  ENP6IDAI
                 Move Spaces             To  ENP6EDAI
                 Move Spaces             To  ENP6PTYI
                 Move Spaces             To  ENP6BRDI
                 Move Spaces             To  ENP6NAMI
                 Move '00'               To  ENP6AGEI
                 Move Spaces             To  ENP6VACI
                 Move Spaces             To  ENP6CHPI
                 Move '00000000'         To  ENP6VALI
                 Move '000000'           To  ENP6PREI
                 Move 'Pet Policy Deleted'
                   To  ERP6FLDO
                 EXEC CICS SEND MAP ('SSMAPP6')
                           FROM(SSMAPP6O)
                           MAPSET ('SSMAP')
                 END-EXEC
                 GO TO ENDIT-STARTIT

             WHEN '4'
                 Move '01IPET'   To CA-REQUEST-ID
                 Move ENP6CNOO   To CA-CUSTOMER-NUM
                 Move ENP6PNOO   To CA-POLICY-NUM
                 EXEC CICS LINK PROGRAM('LGIPOL01')
                           COMMAREA(COMM-AREA)
                           LENGTH(32500)
                 END-EXEC
                 IF CA-RETURN-CODE > 0
                   GO TO NO-DATA
                 END-IF

                 Move CA-ISSUE-DATE      To  ENP6IDAI
                 Move CA-EXPIRY-DATE     To  ENP6EDAI
                 Move CA-P-PETTYPE       To  ENP6PTYI
                 Move CA-P-BREED         To  ENP6BRDI
                 Move CA-P-NAME          To  ENP6NAMI
                 Move CA-P-AGE           To  ENP6AGEI
                 Move CA-P-VACCINATED    To  ENP6VACI
                 Move CA-P-CHIPID        To  ENP6CHPI
                 Move CA-P-INSUREDVALUE  To  ENP6VALI
                 Move CA-P-PREMIUM       To  ENP6PREI
                 EXEC CICS SEND MAP ('SSMAPP6')
                           FROM(SSMAPP6O)
                           MAPSET ('SSMAP')
                 END-EXEC
                 EXEC CICS RECEIVE MAP('SSMAPP6')
                           INTO(SSMAPP6I)
                           MAPSET('SSMAP') END-EXEC

                 Move '01UPET'          To CA-REQUEST-ID
                 Move ENP6CNOI          To CA-CUSTOMER-NUM
                 Move 0                 To CA-PAYMENT
                 Move 0                 To CA-BROKERID
                 Move '        '        To CA-BROKERSREF
                 Move ENP6IDAI          To CA-ISSUE-DATE
                 Move ENP6EDAI          To CA-EXPIRY-DATE
                 Move ENP6PTYI          To CA-P-PETTYPE
                 Move ENP6BRDI          To CA-P-BREED
                 Move ENP6NAMI          To CA-P-NAME
                 Move ENP6AGEI          To CA-P-AGE
                 Move ENP6VACI          To CA-P-VACCINATED
                 Move ENP6CHPI          To CA-P-CHIPID
                 Move ENP6VALI          To CA-P-INSUREDVALUE
                 Move ENP6PREI          To CA-P-PREMIUM
                 EXEC CICS LINK PROGRAM('LGUPOL01')
                           COMMAREA(COMM-AREA)
                           LENGTH(32500)
                 END-EXEC
                 IF CA-RETURN-CODE > 0
                   GO TO NO-UPD
                 END-IF

                 Move CA-CUSTOMER-NUM To ENP6CNOI
                 Move CA-POLICY-NUM   To ENP6PNOI
                 Move ' '             To ENP6OPTI
                 Move 'Pet Policy Updated'
                   To  ERP6FLDO
                 EXEC CICS SEND MAP ('SSMAPP6')
                           FROM(SSMAPP6O)
                           MAPSET ('SSMAP')
                 END-EXEC

                 GO TO ENDIT-STARTIT

             WHEN OTHER

                 Move 'Please enter a valid option'
                   To  ERP6FLDO
                 Move -1 To ENP6OPTL

                 EXEC CICS SEND MAP ('SSMAPP6')
                           FROM(SSMAPP6O)
                           MAPSET ('SSMAP')
                           CURSOR
                 END-EXEC
                 GO TO ENDIT-STARTIT

           END-EVALUATE.


      *    Send message to terminal and return

           EXEC CICS RETURN
           END-EXEC.

       ENDIT-STARTIT.
           EXEC CICS RETURN
                TRANSID('SSP6')
                COMMAREA(COMM-AREA)
                END-EXEC.

       ENDIT.
           EXEC CICS SEND TEXT
                     FROM(MSGEND)
                     LENGTH(LENGTH OF MSGEND)
                     ERASE
                     FREEKB
           END-EXEC
           EXEC CICS RETURN
           END-EXEC.

       CLEARIT.

           Initialize SSMAPP6I.
           EXEC CICS SEND MAP ('SSMAPP6')
                     MAPSET ('SSMAP')
                     MAPONLY
           END-EXEC

           EXEC CICS RETURN
                TRANSID('SSP6')
                COMMAREA(COMM-AREA)
                END-EXEC.

       NO-ADD.
           Evaluate CA-RETURN-CODE
             When 70
               Move 'Customer does not exist'          To  ERP6FLDO
               Go To ERROR-OUT
             When Other
               Move 'Error Adding Pet Policy'          To  ERP6FLDO
               Go To ERROR-OUT
           End-Evaluate.

       NO-UPD.
           Move 'Error Updating Pet Policy'            To  ERP6FLDO
           Go To ERROR-OUT.

       NO-DELETE.
           Move 'Error Deleting Pet Policy'            To  ERP6FLDO
           Go To ERROR-OUT.

       NO-DATA.
           Move 'No data was returned.'                To  ERP6FLDO
           Go To ERROR-OUT.

       ERROR-OUT.
           EXEC CICS SEND MAP ('SSMAPP6')
                     FROM(SSMAPP6O)
                     MAPSET ('SSMAP')
           END-EXEC.

           Initialize SSMAPP6I.
           Initialize SSMAPP6O.
           Initialize COMM-AREA.

           GO TO ENDIT-STARTIT.
