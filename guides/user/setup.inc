%
% Setting Up Your Account
%
\chapter{Setting Up Your Account}
\label{app:setup}

Setting up your account to use \miriad\ and the ATNF Visualisation
Software varies from system to system.
If in doubt, ask a local! We will assume you are using the \verb+csh+
shell.

If you are using the `standard' login scripts on the ATNF machines
(Marsfield, Narrabri, Parkes), you will be prompted whether you wish to 
use \miriad\ and the ATNF Visualisation Software when you
first log in. If you fail to do this, then you can edit the
file \verb+.login.packages+ in your login directory, and change
\verb|-miriad| to \verb|+miriad|. After this change, \miriad\ will be
set-up after your next login.

If you are not using the standard login scripts on ATNF machines,
you will need to include three lines in your \verb+.login+ script.
include;
\begin{verbatim}
       source /applic/miriad/bin/MIRRC
       set path = ($path $MIRBIN)
       source /appplic/karma/.login
\end{verbatim}
Other sites should have similar arrangements -- only the directory
should change.

The operations performed by these lines are simple enough.
The \verb+MIRRC+ script, in the first line, sets up environment
variables (including \verb+MIRBIN+) to point to the appropriate directories.
The second line includes the \miriad\ executables
in your executable search path (you may choose to place it somewhere other
than the end of the search path). The third line sets up the ATNF
Visualisation Software.

You may also wish to set the environment variable \verb+MIRDEF+ to point
to a directory where the keyword files
generated by the \verb+miriad+ front-end should be stored. For example:
\begin{verbatim}
       % setenv MIRDEF /mydirectory/mirdef
\end{verbatim}
By default these keyword files are stored in the directory \verb+~/mirdef+,
if it exists when \verb+MIRRC+ is invoked, or in your current working directory.

The login initialisation script, \verb+MIRRC.sh+, exists for users of the Bourne or Bash
shells. This would typically be invoked in your \verb+.profile+ script.
Like its \verb+csh+ cousin, \verb+MIRRC.sh+ does not modify the \verb+PATH+
environment variable. You will want to include \verb+$MIRBIN+ in
your path.