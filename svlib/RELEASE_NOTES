RELEASE NOTES for svlib version 0.5p1

#########################################
DEFECTS FIXED FOR THIS RELEASE:
#########################################

#35: file_accessible throws if file not accessible
--------------------------------------------------
Fixed (thorsten).

#########################################
ENHANCEMENTS IMPLEMENTED IN THIS RELEASE:
#########################################

#36: Change Str::split() to exhibit behaviour of Perl/Awk regarding whitespace
------------------------------------------------------------------------------
Done, not yet documented (thorsten).

#34: Add split package-level function
-------------------------------------
Added str_split(), not yet documented (thorsten).


RELEASE NOTES for svlib version 0.5

#########################################
DEFECTS FIXED FOR RELEASE 0.5
#########################################

#28: Str::create can cause runtime crash
---------------------------------------
Obstack::obtain now checks for null process handle before interrogating
process::get_randstate().

#29: Add regex_match to documentation
------------------------------------
This package-level function is now documented.

#31: File descriptor argument to foreach_line macro evaluated repeatedly
------------------------------------------------------------------------
This defect has been fixed so that the following idiom works as expected:
  `foreach_line($fopen("MYFILE.TXT","r"), lineVar, lineNumVar) ...

#########################################
ENHANCEMENTS IMPLEMENTED IN RELEASE 0.5:
#########################################

#24: Add Perl-style regex-based split
------------------------------------
Regex::split method, and package-level function regex_split,
implemented and documented.

