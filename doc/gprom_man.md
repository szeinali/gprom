<!-- Creator     : groff version 1.19.2 -->
<!-- CreationDate: Mon Oct  3 19:17:49 2016 -->
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta name="generator" content="groff -Thtml, see www.gnu.org">
<meta http-equiv="Content-Type" content="text/html; charset=US-ASCII">
<meta name="Content-Style" content="text/css">
<style type="text/css">
       p     { margin-top: 0; margin-bottom: 0; }
       pre   { margin-top: 0; margin-bottom: 0; }
       table { margin-top: 0; margin-bottom: 0; }
</style>
<title>gprom</title>

</head>
<body>

<h1 align=center>gprom</h1>

<a href="#NAME">NAME</a><br>
<a href="#SYNOPSIS">SYNOPSIS</a><br>
<a href="#DESCRIPTION">DESCRIPTION</a><br>
<a href="#OPTIONS">OPTIONS</a><br>
<a href="#PLUGINS">PLUGINS</a><br>
<a href="#OPTIMIZATION">OPTIMIZATION</a><br>
<a href="#EXAMPLES">EXAMPLES</a><br>
<a href="#AUTHORS">AUTHORS</a><br>
<a href="#SEE ALSO">SEE ALSO</a><br>

<hr>


<a name="NAME"></a>
<h2>NAME</h2>


<p style="margin-left:11%; margin-top: 1em"><b>gprom</b> -
a command line interface for the GProM provenance database
middleware</p>

<a name="SYNOPSIS"></a>
<h2>SYNOPSIS</h2>


<p style="margin-left:11%; margin-top: 1em"><b>gprom</b>
<i>[connection_options]</i></p>

<p style="margin-left:11%; margin-top: 1em"><b>gprom
&minus;sql</b> <i>query [connection_options]</i></p>

<p style="margin-left:11%; margin-top: 1em"><b>gprom
&minus;sqlfile</b> <i>file [connection_options]</i></p>

<p style="margin-left:11%; margin-top: 1em"><b>gprom
&minus;help</b></p>

<p style="margin-left:11%; margin-top: 1em"><b>gprom
&minus;languagehelp</b> <i>language</i></p>

<a name="DESCRIPTION"></a>
<h2>DESCRIPTION</h2>


<p style="margin-left:11%; margin-top: 1em"><b>GProM</b> is
a database middleware that adds provenance support to
multiple database backends. Provenance is information about
how data was produced by database operations. That is, for a
row in the database or returned by a query we capture from
which rows it was derived and by which operations. The
system compiles declarative queries with provenance requests
into SQL code and executes this SQL code on a backend
database system. GProM supports provenance capture for SQL
queries and transactions, and produces provenance graphs
explaining existing and missing answers for Datalog queries.
Provenance is captured on demand by using a compilation
technique called instrumentation. Instrumentation rewrites
an SQL query (or past transaction) into a query that returns
rows paired with their provenance. The output of the
instrumentation process is a regular SQL query that can be
executed using any standard relational database. The
instrumented query generated from a provenance request
returns a standard relation that maps rows to their
provenance. GProM extends multiple frontend languages (e.g.,
SQL and Datalog) with provenance requests and can produce
code for multiple backends (currently Oracle).</p>

<p style="margin-left:11%; margin-top: 1em"><b>gprom</b> is
a command line interface for GProM. gprom can be called in
several ways as shown above in the synopsis. The first form
starts an interactive shell where the user runs SQL and
utility commands. The second form evaluates a single query
given as parameter <i>query</i>. The third form runs all SQL
commands from file <i>file</i>. The last form describes the
provenance extensions that GProM supports for a particular
frontend language, e.g., <i>oracle</i> for Oracle SQL. See
discussion on parser plugins below for a comprehensive list
of supported frontend languages. See the <b>EXAMPLES</b>
section for some typical usage examples.</p>

<a name="OPTIONS"></a>
<h2>OPTIONS</h2>


<p style="margin-left:11%; margin-top: 1em"><b>HELP</b>
<br>
Options to get help on GProM usage.</p>

<table width="100%" border=0 rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="7%">



<p style="margin-top: 1em" valign="top"><b>&minus;help</b></p> </td>
<td width="4%"></td>
<td width="40%">


<p style="margin-top: 1em" valign="top">show help message
and quit</p></td>
<td width="38%">
</td>
</table>

<p style="margin-left:11%; margin-top: 1em"><b>INPUT</b>
<br>
These options determine whether GProM operates as an
interactive shell or just processes one query. If none of
the options below is set, then an interactive shell is
opened. <b><br>
&minus;sql</b> <i>query</i></p>

<p style="margin-left:22%;">process <i>query</i></p>

<p style="margin-left:11%;"><b>&minus;sqlfile</b>
<i>file</i></p>

<p style="margin-left:22%;">read query to be processed from
<i>file</i></p>

<p style="margin-left:11%; margin-top: 1em"><b>LOGGING AND
DEBUG</b> <br>
Set logging and debugging options.</p>

<table width="100%" border=0 rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="6%">



<p style="margin-top: 1em" valign="top"><b>&minus;log</b></p> </td>
<td width="5%"></td>
<td width="24%">


<p style="margin-top: 1em" valign="top">activate
logging</p> </td>
<td width="54%">
</td>
</table>

<p style="margin-left:11%;"><b>&minus;loglevel</b>
<i>level</i></p>

<p style="margin-left:22%;">set minimum level of log
messages to be shown. Valid settings for <i>level</i> are
<b>0 = NONE</b>, <b>1 = FATAL</b>, <b>2 = ERROR</b>, <b>3 =
INFO</b>, <b>4 = DEBUG</b>, <b>5 = TRACE</b>.</p>

<p style="margin-left:11%; margin-top: 1em"><b>PLUGINS</b>
<br>
Configure plugins. <b><br>
&minus;P</b><i>plugin_type plugin_name</i></p>

<p style="margin-left:22%;">Select <i>plugin_name</i> as
the active plugin for <i>plugin_type</i>. Most components in
GProM are pluggable. See the section on plugins below.</p>

<p style="margin-left:11%; margin-top: 1em"><b>CONNECTION
OPTIONS</b> <br>
Configure the connection to the backend database system.
<b><br>
&minus;host</b> <i>host</i></p>

<p style="margin-left:22%;">Host IP address for backend DB
connection. Default value: <i>ligeti.cs.iit.edu</i>.</p>

<p style="margin-left:11%;"><b>&minus;db</b>
<i>orcl</i></p>

<p style="margin-left:22%;">Database name for the backend
DB connection. For Oracle connections this determines
<i>SID</i> or <i>SERVICE_NAME</i>. Default value:
<i>orcl</i></p>

<p style="margin-left:11%;"><b>&minus;user</b>
<i>user</i></p>

<p style="margin-left:22%;">User for the backend DB
connection. Default value: <i>fga_user</i></p>

<p style="margin-left:11%;"><b>&minus;passwd</b>
<i>password</i></p>

<p style="margin-left:22%;">Use password <i>password</i>
for the backend DB connection.</p>

<p style="margin-left:11%;"><b>&minus;port</b>
<i>port</i></p>

<p style="margin-left:22%;">The TPC/IP network port to use
for the backend DB connection.</p>

<p style="margin-left:11%; margin-top: 1em"><b>PROVENANCE
FEATURES</b> <br>
GProM main purpose is to provide provenance support for
relational databases by instrumenting operations for
provenance capture. These options control certain aspects of
provenance instrumentation. <b><br>
&minus;host</b> <i>host</i></p>

<p style="margin-left:22%;">Host IP address for backend DB
connection. Default value: <i>ligeti.cs.iit.edu</i>.</p>


<p style="margin-left:11%; margin-top: 1em"><b>OPTIMIZATION</b>
<br>
GProM features a heuristic and cost-based optimizer for
relational algebra and provenance instrumentation. These
options control the optimizer. <b><br>
&minus;heuristic_opt</b></p>

<p style="margin-left:22%;">Apply heuristic application of
relational algebra optimization rules. Default value:
<i>FALSE</i>.</p>

<table width="100%" border=0 rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="6%">



<p style="margin-top: 1em" valign="top"><b>&minus;cbo</b></p> </td>
<td width="5%"></td>
<td width="78%">


<p style="margin-top: 1em" valign="top">Apply cost-based
optimization. Default value: <i>FALSE</i>.</p></td>
</table>


<p style="margin-left:11%;"><b>&minus;O</b><i>optimization_option</i></p>

<p style="margin-left:22%;">Activate optimization option.
Most options correspond to equivalence preserving relational
algebra transformations. &minus;O<i>optimization_option</i>
activates the option. To deactivate an option use
&minus;O<i>optimization_option FALSE</i>. For example,
<b>&minus;Omerge_ops</b> activates a rule that merges
adjacent selections and projections in a query. See section
<b>OPTIMIZATION</b> below for a full list of supported
<i>optimization_option</i> values.</p>

<a name="PLUGINS"></a>
<h2>PLUGINS</h2>


<p style="margin-left:11%; margin-top: 1em">Most components
in GProM are pluggable and can be replaced. The following
components are realized as plugins:</p>

<p style="margin-left:11%; margin-top: 1em"><b>parser</b>
<br>
The parser plugin determines what input language is
used.</p>

<p style="margin-left:22%; margin-top: 1em"><b>orcle</b>
&minus; Oracle SQL dialect</p>

<p style="margin-left:22%; margin-top: 1em"><b>dl</b>
&minus; Datalog</p>


<p style="margin-left:11%; margin-top: 1em"><b>executor</b>
<br>
GProM translates statements in an input language with
provenance features into a language understood by a database
backend (this process is called instrumentation). The
executor plugin determines what is done with the
instrumented query produced by GProM.</p>

<p style="margin-left:22%; margin-top: 1em"><b>sql</b>
&minus; Print the generated query to <i>stdout</i></p>

<p style="margin-left:22%; margin-top: 1em"><b>run</b>
&minus; Run the generated query and show its result</p>

<p style="margin-left:22%; margin-top: 1em"><b>dl</b>
&minus; Output a datalog program (only works if <i>dl</i>
analyzer, translator, and parser plugins have been
chosen</p>


<p style="margin-left:11%; margin-top: 1em"><b>analyzer</b>
<br>
This plugin checks the output of the parser for semantic
correctness.</p>

<p style="margin-left:22%; margin-top: 1em"><b>oracle</b>
&minus; Assumes the input is an SQL query written in
Oracle&rsquo;s SQL dialect</p>

<p style="margin-left:22%; margin-top: 1em"><b>dl</b>
&minus; Analyses Datalog inputs</p>


<p style="margin-left:11%; margin-top: 1em"><b>translator</b>
<br>
This plugin translates the input language into <b>relational
algebra</b> which is used as an internal code representation
by GProM.</p>

<p style="margin-left:22%; margin-top: 1em"><b>oracle</b>
&minus; Translates Oracle SQL into relational algebra</p>

<table width="100%" border=0 rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="22%"></td>
<td width="-14%"></td>
<td width="7%"></td>
<td width="85%">


<p valign="top"><b>dl</b> &minus;</p></td>
<tr valign="top" align="left">
<td width="22%"></td>
<td width="-14%"></td>
<td width="7%"></td>
<td width="85%">


<p valign="top">Translates Datalog into relational
algebra</p> </td>
</table>

<p style="margin-left:22%; margin-top: 1em"><b>dummy</b>
&minus; Do not translate the input (this can be used to
produce an output language other than SQL to circumvent the
limitations of GProM&rsquo;s relational algebra model, e.g.,
we currently do not support recursion)</p>


<p style="margin-left:11%; margin-top: 1em"><b>metadatalookup</b>
<br>
The metadata lookup plugin handles communication with the
backend database. This involves 1) running queries over the
catalog of the backend to do, e.g., semantic analysis and 2)
executing queries instrumented for provenance capture to
compute the results of provenance requests submitted by the
user. To be able to do this, the plugin manages a connection
to the backend database using the C library of the backend
DBMS. The type of metadata lookup plugin determines how
connection parameters will be interpreted.</p>

<p style="margin-left:22%; margin-top: 1em"><b>oracle</b>
&minus; This plugin manages communication with an Oracle
database backend. We use Oracle&rsquo;s <i>OCI</i> interface
wrapped by the open source library <i>OCILIB</i>.</p>


<p style="margin-left:22%; margin-top: 1em"><b>postgres</b>
&minus; This plugin manages communication with a PostgreSQL
database backend. We use PostgreSQL&rsquo;s <i>libpq</i>
library.</p>


<p style="margin-left:11%; margin-top: 1em"><b>sqlcodegen</b>
<br>
This plugin translates GProM&rsquo;s internal relational
algebra model of queries into queries written in a
backend&rsquo;s SQL dialect.</p>

<p style="margin-left:22%; margin-top: 1em"><b>oracle</b>
&minus; Output SQL code written in Oracle&rsquo;s SQL
dialect</p>

<p style="margin-left:22%; margin-top: 1em"><b>dl</b>
&minus; Output a Datalog program</p>

<p style="margin-left:11%; margin-top: 1em"><b>cbo</b></p>

<p style="margin-left:22%;"><b>dl</b> &minus;</p>

<a name="OPTIMIZATION"></a>
<h2>OPTIMIZATION</h2>


<p style="margin-left:11%; margin-top: 1em">As mentioned
above GProM features a cost-based and heuristic optimization
for relational algebra expressions. Heuristic optimization
rules are mostly relational algebra equivalences. Cost-base
optimization chooses between alternative options for
instrumenting a query for provenance capture and controls
the application of some of the algebraic equivalence rules
we support.</p>

<p style="margin-left:11%; margin-top: 1em"><b>Relational
algebra transformations</b> <br>
GProM currently implement the following transformation rules
that are activated with <b>-O</b><i>rule</i>:</p>


<p style="margin-left:22%; margin-top: 1em"><b>merge_ops</b>
&minus; merge adjacent projection and selection operators.
Selections will always be merged. However, merging
projections can lead to an explosion of projection
expression size. We actively check for such cases and avoid
merging if this would increase the expression size
dramatically. For example, consider a projection <b>A + A AS
B</b> followed by a projection <b>B + B AS C</b>. Merging
these two projections would result in the projection
expression <b>A + A + A + A AS C</b> which has double the
number of <b>A</b> references as the original projection.
This optimization is important when computing transaction
provenance. For a thorough explanation see the publications
referenced on the GProM webpage.</p>


<p style="margin-left:22%; margin-top: 1em"><b>factor_attrs</b>
&minus; try to factor attributes in projection expressions
to reduce the number of references to attributes. We
currently support addition and multiplication expressions in
<b>CASE</b> constructs. For example, <b>CASE WHEN</b>
<i>cond</i> <b>THEN A + 2 ELSE A END AS A</b> can be
refactored into <b>A + CASE WHEN</b> <i>cond</i> <b>THEN 2
ELSE 0 END AS A</b> to reduce the number of references to
attribute <b>A</b> from 2 to 1.</p>


<p style="margin-left:22%; margin-top: 1em"><b>materialize_unsafe_proj</b>
&minus; Force the backend database to materialize
projections that could lead to uncontrolled expression
growth if they would be merged with adjacent projections (as
explained above for <b>merge_ops</b>).</p>


<p style="margin-left:22%; margin-top: 1em"><b>remove_redundant_projections</b>
&minus; Removes projections that are unnecessary from a
query, e.g., a projection on <b>A, B</b> over a table
<b>R(A,B)</b> is redundant and should be removed to simplify
the query.</p>


<p style="margin-left:22%; margin-top: 1em"><b>remove_redundant_duplicate_removals</b>
&minus; Removes duplicate removal operators if the
application of duplicate removal has no effect on the query
result. We check for two cases here: 1) if the input
relation has at least one candidate key, then there are no
duplicates and the operator has no effect and 2) if the
result of the duplicate removal is later subjected to
duplicate removal by a downstream operator and none of the
operators on the path to this downstream operator are
sensitive to the number of duplicates then the operator can
be safely removed.</p>


<p style="margin-left:22%; margin-top: 1em"><b>remove_redundant_window_operators</b>
&minus; Remove window operators (corresponding to SQL
<b>OVER</b> clause expressions) which produce an output that
is not used by any downstream operators.</p>


<p style="margin-left:22%; margin-top: 1em"><b>remove_unnecessary_columns</b>
&minus; Based on an analysis of which columns of the
relation produced by an operator are used by downstream
operators, we add additional projections to remove unused
columns.</p>


<p style="margin-left:22%; margin-top: 1em"><b>pullup_duplicate_removals</b>
&minus; This optimization tries to pull up duplicate removal
operators.</p>


<p style="margin-left:22%; margin-top: 1em"><b>pullup_prov_projections</b>
&minus; The provenance instrumentation used by GProM
duplicates attributes of input tables using projection and
propagates them to produce results annotated with
provenance. This optimization tries to pull up such
projections to delay the increase of schema sized caused by
duplicating attributes.</p>


<p style="margin-left:22%; margin-top: 1em"><b>selection_move_around</b>
&minus; This optimization applies standard selection
move-around techniques.</p>

<p style="margin-left:11%; margin-top: 1em"><b>Cost-based
optimization options</b></p>

<p style="margin-left:22%;">&minus;</p>

<a name="EXAMPLES"></a>
<h2>EXAMPLES</h2>


<p style="margin-left:11%; margin-top: 1em"><b>Example
1.</b> Connect to an Oracle database (default) at IP
<i>1.1.1.1</i> with SID <i>orcl</i> using user <i>usr</i>
and password <i>mypass</i> at port <i>1521</i> and start an
interactive session:</p>

<p style="margin-left:22%; margin-top: 1em">gprom -host
1.1.1.1 -user usr -passwd mypass -port 1521 -db orcl</p>

<p style="margin-left:11%; margin-top: 1em"><b>Example
2.</b> Same as above, but output instrumented SQL queries to
<i>stdout</i> instead of executing them:</p>

<p style="margin-left:22%; margin-top: 1em">gprom -host
1.1.1.1 -user usr -passwd mypass -port 1521 -db orcl
-Pexecutor sql</p>

<p style="margin-left:11%; margin-top: 1em"><b>Example
3.</b> Using the same database as in examples 1 and 2,
capture provenance of a query <b>SELECT a FROM r</b>:</p>

<p style="margin-left:22%; margin-top: 1em">gprom -host
1.1.1.1 -user usr -passwd mypass -port 1521 -db orcl
-Pexecutor sql \ <br>
-sql &quot;PROVENANCE OF (SELECT a FROM r);&quot;</p>

<a name="AUTHORS"></a>
<h2>AUTHORS</h2>


<p style="margin-left:22%; margin-top: 1em"><b>Bahareh
Arab</b> (<i>barab@hawk.iit.edu</i>)</p>

<p style="margin-left:22%; margin-top: 1em"><b>Su Feng</b>
(<i>sfeng@hawk.iit.edu</i>)</p>

<p style="margin-left:22%; margin-top: 1em"><b>Boris
Glavic</b> (<i>bglavic@iit.edu</i>)</p>

<p style="margin-left:22%; margin-top: 1em"><b>Seokki
Lee</b> (<i>slee195@hawk.iit.edu</i>)</p>

<p style="margin-left:22%; margin-top: 1em"><b>Xing Niu</b>
(<i>xniu7@hawk.iit.edu</i>)</p>

<a name="SEE ALSO"></a>
<h2>SEE ALSO</h2>
<hr>
</body>
</html>