**********************************************************************************;
** Title:   check_all_logs.sas                                                  **;
** Author:  Maria Cupples Hudson                                                **;
** Date:    April 18, 2007                                                      **;
** Purpose: To search all log files for errors, warnings, and uninitialized     **;
**          variables.                                                          **;
** Notes:   You can call the log-checking macro for as many subfolders as you   **;
**          need to.  To find the place where these are called, search for the  **;
**          phrase: HERE IS WHERE YOU CALL THE LOG-CHECKING MACRO and updated   **;
**          or add to the macro calls.                                          **;
** Updates: 06/24/09 modified to work for SESTAT                                **;
**          04/05/13 moddified to search for unable                             **;
**          11/02/20 moddified to search for not exist and to be less project-  **;
**                   specific.                                                  **;
**********************************************************************************;

options ls = 150  pagesize=max;

* Path name where this program will be stored and used. ;
* NOTE that this program is set up to check logs in either the current folder or a;
*      subfolder of the current folder                                            ;
* ALSO NOTE that you need to be careful if you pathname has ampersands, quotation ;
*           marks, or other punctuation. If so, use the %str() or %nrbquote()     ;
*           notations to make sure SAS sees this as a file path. This will be     ;
*           resolved as a part of a directorys statement later. Very important.   ;
%let path = C:\Users\mhudson\marias_projects\SAS_Log_Checker;

* this macro counts the observations in a dataset and returns a global macro variable;
%macro numobs(dsn,nbrobs);
  %global &nbrobs;
  %let datasetid=%sysfunc(open(&dsn));
  %let &nbrobs=%sysfunc(attrn(&datasetid,nlobs));
  %let closing_code=%sysfunc(close(&datasetid));
%mend numobs;

%macro foldercheck(folder=);

  * increment the folder count so we can track folders without  ;
  * depending on folder names to be legitimate SAS names.       ;
  %let folder_count = %eval(&folder_count + 1);

  * Change the logpath and lstpath macro variables if you store ;
  * your log and lst files in different locations. O/W this will;
  * assume that log and lst files are kept in the same folder.  ;
  %let logpath = &path.\&folder;
  %let lstpath = &path.\&folder;

  * Create a listing of all log files in the folder.  We will   ;
  * check every log file in the folder.                         ;

  * The DM statement Submits SAS Program Editor, Log, Procedure ;
  * Output or text editor commands as SAS statements. WPGM is a ;
  * Windows command that changes the active window to the editor;
  * window that was last edited.                                ;

  dm wpgm 'clear log' wpgm; 

  * set a filename for the directory we need to read.           ;
  filename folder1 pipe "dir &logpath.\"; 
  filename folder2 pipe "dir &lstpath.\"; 

  data readlogs (keep = file_name log lst); 
    infile folder1 truncover; 
    length var1  $250. file_name $50.;
    input var1 $ 1-250; 

    * delete header and footer information from directory listing;
    if var1 ne '' and index(var1,"<DIR>")= 0 and index(var1,"Volume in")=0 and
       index(var1,"Volume Serial")=0 and index(var1,"File(s)")=0 and index(var1,"Dir(s)")=0
       and index(var1,"Directory of")=0;
    * substring out file name, extentions, date and time stamps;
    file_name=substr(var1,40,50);

    * Delete the log/lst of this program from consideration;
    if index(upcase(var1),'CHECK_ALL_LOGS')>0 then delete;

    * flag log and lst files for this folder;
    if index(upcase(file_name),".LOG")>0 then log=1;
    else log=0;
    if index(upcase(file_name),".LST")>0 then lst=1;
    else lst=0;

  run;

  data readlsts (keep = file_name log lst); 
    infile folder2 truncover; 
    length var1  $250. file_name $50.;
    input var1 $ 1-250; 

    * delete header and footer information from directory listing;
    if var1 ne '' and index(var1,"<DIR>")= 0 and index(var1,"Volume in")=0 and
       index(var1,"Volume Serial")=0 and index(var1,"File(s)")=0 and index(var1,"Dir(s)")=0
       and index(var1,"Directory of")=0;
    * substring out file name, extentions, date and time stamps;
    file_name=substr(var1,40,50);

    * Delete the log/lst of this program from consideration;
    if index(upcase(var1),'CHECK_ALL_LOGS')>0 then delete;

    * flag log and lst files for this folder;
    if index(upcase(file_name),".LOG")>0 then log=1;
    else log=0;
    if index(upcase(file_name),".LST")>0 then lst=1;
    else lst=0;

  run;
  
  * comment this print statment back in if you need more info about the directory;
  /*
  title "Directory listing that we are checking";
  proc print data=folder_&folder_count;
  run;
  title;
  */

  data logs_&folder_count. lsts_&folder_count.;
    set readlogs readlsts;
    if log=1 then output logs_&folder_count.;
    if lst=1 then output lsts_&folder_count.;
  run;

  proc sort data= logs_&folder_count nodupkey; by file_name log lst; run;
  proc sort data= lsts_&folder_count nodupkey; by file_name log lst; run;

  * run numobs to get the number to check.;
  %numobs(logs_&folder_count., logs_&folder_count.);
  %numobs(lsts_&folder_count., lsts_&folder_count.);

  * Output the file names of all log files to macro variables;
  data _null_;
    set logs_&folder_count. end=last ;
    length vbl $6.;
    vbl = compress("log"||_n_);
    call symput(vbl,left(trim(file_name)));
  run;

  * Output the file names of all lst files to macro variables;
  data _null_;
    set lsts_&folder_count. ;
    length vbl $6.;
    vbl = compress("lst"||_n_);
    call symput(vbl,left(trim(file_name)));
  run;

  %macro logfile;

    %if &&logs_&folder_count. ne 0 %then %do i = 1 %to &&logs_&folder_count.;

      filename log&i. "&logpath.\&&log&i";

      * read in the log file line by line;
      data logs_&folder_count._&i. (keep = filename folder nume numw numi numr numa numn);
        format line  $char300. filename logname $char100. folder $15.;
        infile log&i. dsd truncover lrecl=5000 end=last;
    
        * initialize counts to zero and retain through the data step;
        if _n_ = 1 then do;
          nume = 0;
          numw = 0;
          numi = 0;
          numr = 0;
          numa = 0;
          numn = 0;
        end;
        retain nume numw numi numr numa numn;

        * pull in each line in the log file;
        input @1 line $char300.;
    
        * look for the words ERROR, WARNING, and UNINITIALIZED;
        * if you find them increment the appropriate counts.  ;
        if index(upcase(line),'ERROR')>0 
          and index(upcase(line),'ERROR(FALSE)')=0 
          and index(upcase(line),'ERROR(TRUE)')=0 
          and index(upcase(line),'ERROR CHECK')=0 
          and index(upcase(line),'ERROR-CHECK')=0 
          and index(upcase(line),'ERROR BOX')=0 
          and index(upcase(line),'ERROR DETECT')=0 
          and index(upcase(line),'ERROR-DETECT')=0 
          then nume = nume + 1;
        if index(upcase(line),'WARNING')>0 
          and index(upcase(line),"UNABLE TO COPY SASUSER")=0
          and index(upcase(line),'DATA TOO LONG FOR COLUMN')=0 
          and index(upcase(line),'MULTIPLE LENGTHS WERE SPECIFIED FOR THE BY VARIABLE SAS_NAME')=0
          and index(upcase(line),'WARNING BOX')=0 
          and index(upcase(line),'POP UP A WARNING')=0 
          and index(upcase(line),'WARNING WILL POP')=0 
          then numw = numw + 1;
        if index(upcase(line),'UNINITIALIZED')>0 then numi = numi + 1;
        if index(upcase(line),'REPEAT OF BY')>0 or 
           index(upcase(line),'REPEATS OF BY')>0 then numr = numr + 1;
        if index(upcase(line),'UNABLE')>0 
           and index(upcase(line),'UNABLE TO OPEN SASUSER')=0 
           and index(upcase(line),"UNABLE TO COPY SASUSER")=0 
           and index(upcase(line),"TEMPLATE 'STYLES.XLPRINT' WAS UNABLE TO WRITE")=0
           then numa = numa + 1;
        if index(upcase(line),'NOT EXIST')>0 
           and index(upcase(line),'BASE DATA SET DOES NOT EXIST. DATA FILE IS BEING COPIED TO BASE FILE')=0 
           then numn = numn + 1;

        if last then do;
          logname = "&&log&i";
          filename = substr(logname,1,index(logname,".")-1);
          folder="&folder";
          output;
        end;
      run;
  
      proc append data=logs_&folder_count._&i. base=logs;
      run;

    %end;

  %mend logfile;  
  %logfile;

  %macro lstfile;

    %if &&lsts_&folder_count. ne 0 %then %do i = 1 %to &&lsts_&folder_count.;

      filename lst&i. "&lstpath.\&&lst&i";

      * read in the log file line by line;
      data lsts_&folder_count._&i. (keep = filename folder nump);
        format line  $char300. filename lstname $char100. folder $15.;
        infile lst&i. dsd truncover lrecl=5000 end=last;
    
        * initialize count to zero and retain through the data step;
        if _n_ = 1 then do;
          nump = 0;
        end;
        retain nump;

        * pull in each line in the log file;
        input @1 line $char300.;
    
        * Look for the word PROBLEM (as long as it is not related to any variables named PROBLEM_xxx).;
        if index(upcase(line),'PROBLEM')>0 and index(upcase(line),'PROBLEM_')=0
          and index(upcase(line),'PROBLEM CASES PRINT')=0 
          and index(upcase(line),'PROBLEM OBSERVATIONS (IF ANY) WILL BE PRINTED')=0
          and index(upcase(line),'PRINTING PROBLEM')=0 then nump = nump + 1;

        if last then do;
          lstname = "&&lst&i";
          filename = substr(lstname,1,index(lstname,".")-1);
          folder="&folder";
          output;
        end;
      run;
  
      proc append data=lsts_&folder_count._&i. base=lsts;
      run;

    %end;

  %mend lstfile;  
  %lstfile;

%mend foldercheck;

* Create blank log/lst datasets that we will append to;
data logs (keep = filename folder nume numw numi numr numa numn)
     lsts (keep = filename folder nump);
  format filename lstname $char100. folder $15. nume numw numi numr numa numn nump 8.;
  filename = '';
  folder = '';
  array nums (*) _numeric_;
  do i = 1 to dim(nums); nums(i) = .; end;
  if filename ne '';
run;


* intialize the folder count to be zero;
%let folder_count = 0;

************  HERE IS WHERE YOU CALL THE LOG-CHECKING MACRO   ************;
%foldercheck(folder=); 
%foldercheck(folder=example_logs); 

proc sort data=logs;
  by folder filename;
run;

proc sort data=lsts;
  by folder filename;
run;

data allfiles;
  merge logs lsts;
  by folder filename;
run;

* print results to lst file;
data _null_;
  set allfiles end=last;
  by folder;
  length folderprint $25.;
  folderprint = "Folder "||left(trim(folder));
  file print;

  if _n_ = 1 then do;
    put @1 "**********************************************************************************************************************************";
    put @1 "*" @130 "*";
    put @1 "* Summary issues found in log files" @130 "*";
    put @1 "*" @130 "*";
  end;

  if first.folder then do;
    put @1 "**********************************************************************************************************************************";
    put @1 "*" @35 folderprint @130 "*";
    put @1 "**********************************************************************************************************************************";
    put @1 "*" @130 "*";
    put @1 "*"           @40 " Number"                                @70 "    Number"     @85 "    Number"     @100 "    Number"     @115 "    Number"     @130 "*";
    put @1 "*"           @40 " of LST " @50 "Number"  @60 " Number"   @70 "   of LOG"      @85 "   of LOG"      @100 "   of times"    @115 "  of time we"   @130 "*";
    put @1 "*"           @40 "Possible" @50 "of LOG"  @60 " of LOG"   @70 "Uninitialized"  @85 " REPEAT of BY"  @100 "  we see the "  @115 " see the words" @130 "*";  
    put @1 "* Filename"  @40 "Problems" @50 "Errors"  @60 "Warnings"  @70 "  Variables"    @85 "  Variables "   @100 "  word UNABLE"  @115 "  NOT EXIST  "  @130 "*";
    put @1 "* --------"  @40 "--------" @50 "------"  @60 "---------" @70 "-------------"  @85 "--------------" @100 "--------------" @115 "--------------" @130 "*";
    put @1 "*" @130 "*";
  end;
  put @1 "* " filename    @42 nump  @52 nume   @62 numw  @76 numi   @91 numr @106 numa @121 numn @130 "*";  
  if last then put @1 "**********************************************************************************************************************************";

run;
