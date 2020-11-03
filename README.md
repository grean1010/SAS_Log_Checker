# SAS_Log_Checker
SAS code to read log and lst files to scan for key words

## Motivation
I wrote the original version of this code for a project that ran a set of 5 programs for 8 different vendors.  We were required to keep seperate records of program runs so that each vendor could be assured of a validated run and no vendor could see the results of another vendor's run.  This meant that each program-vendor combination had a SAS log and lst file that needed to be checked.  It was a drudgery and I found it too easy to lose focus and miss key issues when searching through so many files.  Any rote process can be automated so that's what I did.
<p>Since then I have used this on many other projects.  On one project I had 300 vendors and there was simply no feasible way to check that many log files.  In that case, I actually printed the results to a spreadsheet that could be used to target email results to vendors whose submissions did not pass quality checks.  This can be a great way to automate checking and point to next steps in your QA process.

## Basic methods
SAS log and lst files are plain text.  This means SAS can read it in using an infile statement and scan it for key words.  Originally I only searched for "error", "warning", and "uninitialized" but over time I've added other key phrases to the search terms.  Within my code, I also have many proc print statements that output only if there is a problem in the data.  For example, I will run a proc print with a where clause that looks for bad data (impossible dates, duplication, etc).  The title statement for these printouts contain the word "PROBLEM" so I search my lst files for those words.  

## How to use this code
I'm not gonna lie.  It's finicky.  You should get to know the code and tailor it to your specific projects.  The end result is a really useful printout of how many times each of the key phrases was detected in the log/lst file.  It gives you a starting point for targeting your log checks.  See below for general instructions for getting this up and running.
1. Set the path name.  Usually, I have this be the parent folder where I'm keeping my code.  
2. If your log and lst files are in different folders, then set the logpath and lstpath macro variables accordingly.  If you do not change them, the program will assume that hte log and lst files are in the same subfolder that you are checking.
3. Search for the test "HERE IS WHERE YOU CALL THE LOG-CHECKING MACRO".  Add as many calls to the foldercheck macro as you need.  Each value of the input macro variable 'folder' will be a subfolder of the 'path' you set in step 1.  Leave folder blank to check the top folder (path).
4. Run the code, preferably in batch mode.

## Other notes
There are some cases where the word 'error' is not actually a problem.  I have these situations excluded-- for example, 'error-detect' is a phrase that comes up when using proc import and is not an error.  Similarly there are cases where 'warning' is not an issue.  I have used this on projects where there are other times that I do not want ot flag the word 'error' as a problem and I have tailored the program to accomodate that.  One good example of that is a project where we calculated standard errors and that phrase was used in the comments.  In another case, someone named variables error_type1, error_type2, etc.  It is easy enough to add these to the list of phrases that will not trigger the error count.
