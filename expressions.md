---
id: expressions
title: Understanding Expressions in Aerospike
---

# Understanding Expressions in Aerospike Test

This notebook describes how expressions work in Aerospike: how they are
formed, their syntax, benefits, and how they are used in filters and
operations.

This notebook requires Aerospike database running on localhost. Visit
[Aerospike notebooks
repo](https://github.com/aerospike-examples/interactive-notebooks) for
additional details and the docker container.

## Introduction

In this notebook, we will see how expressions work in Aerospike and
benefits they provide.

The expressions functionality has been enhanced in Aerospike Database
5.6. Expressions appear in two flavors in the client library: Filter
Expressions and Operation Expressions. Filter Expressions provide a
mechanism to select records for operations and replace Predicate
Expressions, which have been deprecated since the 5.2 release. Operation
Expressions enable new read and write capabilities as described later.
Expressions are also used on server as XDR Filter Expressions to specify
which records are shipped to remote destinations.

We will describe at a high level how expressions are formed in Aerospike
and the capabilities they enable. After highlighting key syntax
patterns, we will show with specific code examples how expressions are
used.

The main topics in this notebook include:

-   scope of expressions
-   benefits
-   syntax
-   usage
-   coding examples

## Prerequisites

This tutorial assumes familiarity with the following topics:

-   [Aerospike Notebooks - Readme and Tips](../readme_tips.ipynb)
-   [Hello World](hello_world.ipynb)
-   [Introduction to Data Modeling](java-intro_to_data_modeling.ipynb)

## Setup

### Ensure Database is Running

This notebook requires that Aerospike database is running.

``` java
import io.github.spencerpark.ijava.IJava;
import io.github.spencerpark.jupyter.kernel.magic.common.Shell;
IJava.getKernelInstance().getMagics().registerMagics(Shell.class);
%sh asd
```

### Download and Install Additional Components.

Install the Aerospike Java client version 5.1.3 (or higher) that has the
support for expressions.

``` java
%%loadFromPOM
<dependencies>
  <dependency>
    <groupId>com.aerospike</groupId>
    <artifactId>aerospike-client</artifactId>
    <version>5.1.3</version>
  </dependency>
</dependencies>
```

### Initialize Client

Initialize the client. Also, define constants including the namespace
`test` and set `expressions` and a convenient function
`truncateTestData`.

``` java
import com.aerospike.client.AerospikeClient;

AerospikeClient client = new AerospikeClient("localhost", 3000);
System.out.println("Initialized the client and connected to the cluster.");

final String Namespace = "test";
final String Set = "expressions";

// convenience functions to truncate test data
void truncateTestData() {
    try {
        client.truncate(null, Namespace, Set, null);
    }
    catch (AerospikeException e) {
        // ignore
    }
}
```

> Initialized the client and connected to the cluster.

### Access Shell Commands

You may execute shell commands including Aerospike tools like
[aql](https://docs.aerospike.com/docs/tools/aql/index.html) and
[asadm](https://docs.aerospike.com/docs/tools/asadm/index.html) in the
terminal tab throughout this tutorial. Open a terminal tab by selecting
File-\>Open from the notebook menu, and then New-\>Terminal.

# Defining Expressions

*An expression is a syntactic entity in a programming language that may
be evaluated to determine its
value.*\[(Wikipedia)\](<a href="https://en.wikipedia.org/wiki/Expression_(computer_science\)" class="uri">https://en.wikipedia.org/wiki/Expression_(computer_science\)</a>)

In other words, an expression evaluates to (or returns) a value. Some
simple examples of an expression would be: `<pre>`{=html} 5 7 + 3 2 \> 1
`</pre>`{=html}

Expressions can have:

-   constants: `<pre>`{=html}5, “horse”, \[1, 2, 3\]`</pre>`{=html}
-   variables: `<pre>`{=html}var x = pow(b, c) + d`</pre>`{=html}
-   functions: `<pre>`{=html}pow, mod, min`</pre>`{=html}
-   and operators: `<pre>`{=html}==, +, or`</pre>`{=html}

Expressions are composable. In other words, complex expressions can be
formed from simpler expressions. For example: `<pre>`{=html} 1 + min(2,
a + 2) \< sqrt(b) `</pre>`{=html}

An expression is not an assignment: An expression does not assign a
value to a variable, but simply evaluates to a value which may be used
in an assignment statement that assigns the value to a variable.

# Expressions in Aerospike

This section provides a higher level view of the capabilities and
workings of expressions in Aerospike. The subsequent sections will drill
down into the details.

## Evaluation Context

Expressions are evaluated on server for filtering conditions, reading
and writing to bins, and configuring XDR replication. Therefore, an
expression only works on server data entities such as the metadata and
record data, and uses any constants that the client may provide. When
used from the client library, expressions are created on the client and
sent to the server in an API operation. Before sending, the client
object format of an expression is converted to a wire format using the
`build` operation.

## Components and Scope

*An expression is a combination of one or more constants, variables,
functions, and operators that the programming language interprets ...
and computes to produce another value.*
\[(Wikipedia)\](<a href="https://en.wikipedia.org/wiki/Expression_(computer_science\)" class="uri">https://en.wikipedia.org/wiki/Expression_(computer_science\)</a>)

In Aerospike, expressions use bins and metadata as variables, metadata
and API functions, and values that ae strongly typed as boolean,
integer, float, string, list, map, blob, GeoJSON, or HyperLogLog. A host
of arithmetic, logical, convenience, and API operations are available
for these data.

Please refer to the
[documentation](https://docs.aerospike.com/docs/guide/expressions/) for
the list of supported components.

## Immutability of Components

In Aerospike, an expression works on a transient copy, therefore
evauating an expression does not change the metadata or bins that are
used in the expression.

## Use of Variables

A variable can be defined to represent a sub-expression for syntactic
clarity and efficiency. A variable is first defined and initialized by
assigning it to an expression, and then used as a substitute for the
expression. In the example below, a variable `myvar` is defined and used
in an expression `myexpr`: `<pre>`{=html} myvar = (a + b) / min(a, b)
myexpr = myvar + 1 / myvar `</pre>`{=html}

## Conditional Evaluation

An expression can be condiitonally evaluated with an `if-then-else` like
construct. For example: `<pre>`{=html} if (cond_1) { myexpr = expr_1; }
else if (cond_2) { myexpr = expr_2; } ... else { myexpr = default; }
`</pre>`{=html}

## Uses and Types

Expressions are used in:

-   selection conditions aka predicates (called Filter Expressions),
-   operations (called Operation Expressions), and
-   XDR's shipping configuration (called XDR Filter Expressions).

The functionality of expressions is the same, although the context
determines their use. For example, Filter and XDR Filter Expressions are
boolean expressions, whereas Operation Expressions can evaluate to any
supported type.

Only Filter and Operation Expressions can be used in the client library
and therefore will be the focus of this tutorial. Please refer to the
[documentation](https://docs.aerospike.com/docs/guide/expressions/#xdr-filter-expressions)
for the details of XDR Filter Expressions.

# Benefits of Expressions

Here are some key benefits and capabilities that expressions enable:

-   Capabilities in expressions include:

    -   variables for syntactic clarity and efficiency,
    -   conditional evaluation,  
    -   access to metadata and bin data, and
    -   access to powerful APIs and enhanced set of operators.

-   The enhanced filtering expressions allow records to be processed
    more efficiently by avoiding the need for potentially more expensive
    client or UDF based processing.

-   Reads and writes are now possible with Operation Expressions.

    -   in reads, this can eliminate the need to bring large amounts of
        data to the client with more precise ability to specify the data
        to be fetched.
    -   a bin can be updated with the results of an expression, which
        can eliminate having to read before update by allowing
        everything to happen on the server side in the same request
        including the read, processing for update, and update. This
        saves a round-trip and transfer of potentially large data. In a
        concurrent setting, this also avoids retries due to conflicts
        [see the R-M-W
        pattern](../python/transactions_rmw_pattern.ipynb).

-   Multi-step operations that can build on each other’s results are now
    possible through operation expressions.

# Syntax Details

With a better understanding of their structure, it is easier to parse
Aerospike expressions.

## Notation

Aerospike expressions use [Polish
Notation](https://en.wikipedia.org/wiki/Polish_notation) (aka prefix
notation) which is widely seen in most programming language functions:
`fn(a, b)`. So the expression `5 + 3` in Aerospike Java client would be:
`<pre>`{=html} Exp.add( Exp.val(5), Exp.val(3)) `</pre>`{=html} Note,
the overloaded `val` method converts all suported types to a `Value`
object, which provides an abstraction for all supported value types.

## Composition

A complex expression can be composed using two or more sub-expressions.
For example, with integer bins `a` and `b`, the expression
`(a - b) / (a + b)` would be: `<pre>`{=html} Exp.div( Exp.sub(
Exp.intBin("a"), Exp.intBin("b")), Exp.add( Exp.intBin("a"),
Exp.intBin("b"))) `</pre>`{=html} Note, there are corresponding access
methods to access bin values for other supported types. Since a bin may
hold any value type, an incorrect type access results in an error. A
conditional type check may be used to prevent a run-time error.

## Variable Definition and Use

The `let` construct defines the scope of variables and the expression
that uses them. The `def` construct defines a variable and assigns it to
an expression. Another expression in the scope can use the variable as a
substitute for the expression it defines. For example, in the expression
`5 < (a + b) < 10` using a variable `x` for the sum of integer bins `a`
and `b`: `<pre>`{=html} Exp.let( // let defines the scope of variables
for this expression Exp.def("x", // def defines a variable Exp.sum( //
and also assigns it to an expression Exp.intBin("a"),
Exp.intBin("b")),  
Exp.and( // the expression in let scope can use the variable Exp.lt(
Exp.val(5), Exp.var("x")), // var to use the variable Exp.lt(
Exp.var("x"), Exp.val(10)))); `</pre>`{=html} Note in the above example,
the variable `x` avoids repetitive access to the bins `a` and `b`. Also,
variables defined in `let` cannot be used beyond its scope.

## Conditional Evaluation

The `cond` construct includes one or more pairs of `bool exp, value exp`
followed by a default value: `<pre>`{=html} bool exp1, value exp1, bool
exp2, value exp2, ..., default-value `</pre>`{=html} It evaluates like
the if-then-else logic: the expression takes the value of the first
`value exp` in the sequence whose corresponding `bool exp` evaluates to
true. If all boolean conditions fail, then it evaluates to the last
default-value.

So an expression to evaluate a simple `risk` value "high" or "normal"
based on int bin `age` and bool bin `comorbidities` would be:
`<pre>`{=html} // if (age \> 65 && comorbidities) {risk = "high";} //
else {risk = "normal";} Exp.cond( Exp.and( Exp.gt( Exp.intBin("age"),
Exp.val(65)), Exp.boolBin(comorbidities)), Exp.val("high"),
Exp.val("normal")); `</pre>`{=html}

## Useful Syntax Patterns

Here is a table that summarizes some useful expression syntax patterns.

| Expression                                 | Syntax Example                                                     |
|:-------------------------------------------|:-------------------------------------------------------------------|
| 3                                          | Exp.val(3))                                                        |
| "abc"                                      | Exp.val("abc")                                                     |
| \|-3\|                                     | Exp.abs(Exp.val(-3))                                               |
| 1 + 2                                      | Exp.add(Exp.val(1)), Exp.val(2))                                   |
| var a = 5                                  | Exp.def("a", Exp.val(5))                                           |
| 2 \> 3                                     | Exp.gt(Exp.val(2), Exp.val(3)                                      |
| Function lastUpdateTime                    | Exp.lastUpdateTime()                                               |
| List API listSize                          | ListExp.listSize(list)                                             |
| Composition a + 2 \* b                     | Exp.add(Exp.var(a), Exp.mul(Exp.val(2), Exp.var(b))                |
| Condtional eval if (a == 1) then 2; else 3 | Exp.cond(Exp.eq(Exp.var("a"), Exp.val(1)), Exp.val(2), Exp.val(3)) |
| Integer "bin" value                        | Exp.intBin("bin")                                                  |

# Coding Patterns

An expression object is constructed on the client to be sent to the
server where it is evaluated and used.

An expression's wire protocol representation is constructed with the
`build()` function. A simple expression `fname == "Frank"` will be built
thus: `<pre>`{=html} Expression simpleExp = Exp.build( Exp.eq(
Exp.stringBin("fname"), Exp.val("Frank"))); `</pre>`{=html}

Note the wire protocol representation of expression is of type
`Expression`, whereas a client object is of type `Exp`.

An expression can be used as a filter expression or an operation
expression, as described below.

Both filter and operation expressions can be used independently of each
other and also in the same API call.

## Filter Expressions

Filter expressions are so named because they are used as a condition to
select or discard a record. They always evaluate to a boolean value to
indicate whether the record is selected (true) or filtered out (false).
A filter expression, as the deprecated Predicate Expression, is sent to
the server through the API's policy object parameter. `<pre>`{=html}
Policy policy = new Policy(); policy.filterExp = Exp.build( // sent
through filterExp attribute of policy Exp.eq( Exp.intBin("a"),
Exp.val(11)));  
... client.query(policy, stmt) // policy is specified as a parameter in
API calls `</pre>`{=html}

## Operation Expressions

Operation expressions as the name suggests are used in an operation -
either to read from bins or write to a bin. Specifically they are used
in `read` and `write` methods of `ExpOperation`.

The basic computational model of `operate`, where operation expressions
are used, remains the same: A series of read or write operations are
performed in a given sequence on a single record. What is new is that a
read operation can be an expression involving zero or more bins. Also, a
write operation can get the value from an expression (enabling, for
example, use of cross-bin data with conditional logic) instead of a
simple constant to update a bin.

A read with operation expression can also use an arbitrary name for the
"computed bin" similar to the "as" keyword in the SQL statement
`SELECT expr AS bin`.

The pattern for coding an Operation Expression is:

1.  Define Expression to read or write the bins.
2.  Use `Expression` object in `ExpOperation.read` or `.write` method
    that returns an `Operation`.
3.  Use "expression operations" in any API call that takes an operation
    list.

This is illustrated below.

```{=html}
<pre>
// operate expression with write 
// 1. Define Expression to write the bin with.
//    if (age > 65 && comorbidities) {risk = "high";} 
//    else {risk = "normal";}
Expression writeExp = Exp.build(
        Exp.cond(
            Exp.and(
                Exp.gt(
                    Exp.intBin("age"), Exp.val(65)),
                Exp.boolBin(comorbidities)),
            Exp.val("high"), 
            Exp.val("normal"));
// 2. Use Expression object in ExpOperation.write method.
Operation writeExpOp = ExpOperation.write("risk",
                             Expression writeExp,   // evaluates bin value to update 
                             ExpWriteFlags.DEFAULT);

// operate expression with read
// 1. Define Expression to read bins.
//    read "yes" if (risk == "high" or worktype == "frontline") else "no" 
//    as a computed bin "eligible"
Expression readExp = Exp.build(
        Exp.cond(
            Exp.or(
                Exp.eq(
                    Exp.stringBin("risk"), Exp.val("high")),
                Exp.eq(
                    Exp.stringBin("worktype"), Exp.val("frontline"))),
            Exp.val("yes"),
            Exp.val("no")));
// 2. Use Expression object in ExpOperation.read method.
Operation readExpOp = ExpOperation.read("eligible",   // named "computed bin"
                             Expression readExp,      // evaluates value to return 
                             ExpReadFlags.DEFAULT);
                             
// 3. Use "expression operations" in any API call that takes an operation list.                            
Record record = Client.operate(WritePolicy policy, Key key, Operation writeExpOp, Operation readExpOp);
</pre>
```
# Code Examples

Below are code examples that illustrate the expression features
described above.

## Filter Expressions

The following example illustrates the capabilities of filtering on
metadata and use of List APIs (neither are possible with the deprecated
predicate expressions).

In this illustrative example the filter selects:

-   recently updated (sinceUpdate \< 2) records
-   with list bin having a range of values (i.e., max value - min value)
    greater than 1000.

1.  Populate the test data with 20 records with an integer bin "bin1"
    values 1-20 and a list bin having 3 randomly selected numbers in the
    range 1 to 2000.
2.  Sleep for 2 seconds,
3.  Touch the even numbered records.
4.  Run the query with the filter.

The results should only contain even valued bin1 and bin2 with value
range \> 1000.

``` java
import java.util.ArrayList;
import java.util.Random; 
import com.aerospike.client.AerospikeException;
import com.aerospike.client.Bin;
import com.aerospike.client.Key;
import com.aerospike.client.policy.WritePolicy;
import com.aerospike.client.policy.QueryPolicy;
import com.aerospike.client.exp.Exp;
import com.aerospike.client.exp.ListExp;
import com.aerospike.client.Operation;
import com.aerospike.client.task.ExecuteTask;
import com.aerospike.client.query.Statement;
import com.aerospike.client.query.RecordSet;
import com.aerospike.client.Record;
import com.aerospike.client.cdt.ListReturnType;

// start with a clean state
truncateTestData();

// 1. Populate the test data with 20 records with an integer bin "bin1" values 1-20 
//    and a list bin having 3 randomly selected numbers in the range 1 to 2000.

Random rand = new Random(1); 
final int LIST_RANGE = 2000;
WritePolicy wpolicy = new WritePolicy();
wpolicy.sendKey = true;
for (int i = 1; i <= 20; i++) {
    Key key = new Key(Namespace, Set, "id-"+i);
    Bin bin1 = new Bin(new String("bin1"), i);
    ArrayList<Integer> intList = new ArrayList<Integer>();
    intList.add(rand.nextInt(LIST_RANGE));
    intList.add(rand.nextInt(LIST_RANGE));
    intList.add(rand.nextInt(LIST_RANGE));
    Bin bin2 = new Bin(new String("bin2"), intList);
    client.put(wpolicy, key, bin1, bin2);
}
System.out.println("Test data populated.");;

// 2. Sleep for 2 seconds, 
Thread.sleep(2000);

// 3. Touch the even numbered records.
Statement stmt = new Statement();
stmt.setNamespace(Namespace);
stmt.setSetName(Set);

WritePolicy policy = new WritePolicy();
policy.filterExp = Exp.build(
                        Exp.eq(
                            Exp.mod(Exp.intBin("bin1"), Exp.val(2)),
                            Exp.val(0)));

ExecuteTask task = client.execute(policy, stmt, Operation.touch()); 
task.waitTillComplete(500, 1000);
System.out.println("Touched even numbered records.");;

// 4. Run the query with the filter.
//    records updated in last 2 seconds and whose list value range is more than 1000
Statement stmt = new Statement();
stmt.setNamespace(Namespace);
stmt.setSetName(Set);

// expression filter is specifed in the operation policy
QueryPolicy policy = new QueryPolicy(client.queryPolicyDefault);
policy.filterExp = Exp.build(
    Exp.and(
        Exp.lt(Exp.sinceUpdate(), Exp.val(2000)),   // updated in last 2s
        Exp.gt(   // range of values in bin2 greater than 1000
            Exp.sub(ListExp.getByRank(ListReturnType.VALUE, Exp.Type.INT, Exp.val(-1), Exp.listBin("bin2")),   // largest
                    ListExp.getByRank(ListReturnType.VALUE, Exp.Type.INT, Exp.val(0), Exp.listBin("bin2"))),   // smallest
            Exp.val(1000))));

RecordSet rs = client.query(policy, stmt);

System.out.println("Results of filter expression query (all even records with bin2 max-min > 1000):");
while (rs.next()) {
    Key key = rs.getKey();
    Record record = rs.getRecord();
    System.out.format("key=%s bins=%s\n", key.userKey, record.bins);
}
rs.close();
```

> Test data populated.  
> Touched even numbered records.  
> Results of filter expression query (all even records with bin2 max-min \> 1000):  
> key=id-4 bins={bin1=4, bin2=\[1748, 569, 473\]}  
> key=id-10 bins={bin1=10, bin2=\[153, 1437, 1302\]}  
> key=id-18 bins={bin1=18, bin2=\[333, 1676, 55\]}  
> key=id-16 bins={bin1=16, bin2=\[592, 220, 1888\]}

You may view the state of the database and ensure correctness of the
output by running the following command in the terminal tab:

`aql -c "select * from test.expressions"`

## Operation Expressions

In the following example, these new capabilites that were not possible
earlier are illustrated:

-   expressions involving zero or more bins to write a bin
-   named "computed bins" that return the value of a specified
    expression involving zero or more bins
-   conditional evaluation of expression
-   use of variables in an expression

The code has the following steps:

1.  The test data is populated with three randomly generated test scores
    ranging from 50 to 100 for student ids 1-20.
2.  The data is updated by writing two additional bins: "class" which
    represents the teacher's input (0-10) based on class participation,
    and "grade" which is computed by adding "classwork" to average of
    test scores, and using this formula to compute the grade: 50-70 -\>
    C, 65==70-85 -\> B, 85+ -\> A.
3.  A report is then generated for the id, grade, total score, and
    min/max/average of test scores.

``` java
import com.aerospike.client.exp.Expression;
import com.aerospike.client.exp.ExpOperation;
import com.aerospike.client.exp.ExpReadFlags;
import com.aerospike.client.exp.ExpWriteFlags;
    
// start with a clean state
truncateTestData();

// 1. The test data is populated with three randomly genrated test scores ranging from 50 to 100 
//    for student ids 1-20.

Random rand = new Random(1); 
final int SCORE_RANGE = 50;
WritePolicy wpolicy = new WritePolicy();
wpolicy.sendKey = true;
for (int i = 1; i <= 20; i++) {
    Key key = new Key(Namespace, Set, "id-"+i);
    Bin id = new Bin(new String("id"), i);
    ArrayList<Integer> testScores = new ArrayList<Integer>();
    testScores.add(50 + rand.nextInt(SCORE_RANGE));
    testScores.add(50 + rand.nextInt(SCORE_RANGE));
    testScores.add(50 + rand.nextInt(SCORE_RANGE));
    Bin tests = new Bin(new String("tests"), testScores);
    client.put(wpolicy, key, id, tests);
}
System.out.println("Test data populated.");;

// 2. The data is updated by writing two additional bins: "class" which represents the teacher's input (0-10) 
//    based on class participation, and "grade" which is computed by adding "classwork" to average of test scores, 
//    and using this formula: 50-70 -> C, 65==70-85 -> B, 85+ -> A.

// define the expressions for average test score, total score, grade, min test score, and max test score
Exp avgScoreExp = Exp.let(
                    Exp.def("testsBin", Exp.listBin("tests")),
                    Exp.div(
                        Exp.add(ListExp.getByIndex(ListReturnType.VALUE, Exp.Type.INT, Exp.val(0), Exp.var("testsBin")),
                                ListExp.getByIndex(ListReturnType.VALUE, Exp.Type.INT, Exp.val(1), Exp.var("testsBin")),
                                ListExp.getByIndex(ListReturnType.VALUE, Exp.Type.INT, Exp.val(2), Exp.var("testsBin"))),
                        Exp.val(3)));
Expression avgScoreExpression = Exp.build(avgScoreExp);

Exp totalScoreExp = Exp.let(
                    Exp.def("classBin", Exp.intBin("class")),
                    Exp.add(avgScoreExp, Exp.var("classBin")));
Expression totalScoreExpression = Exp.build(totalScoreExp);

Exp gradeExp = Exp.let(
                    Exp.def("total", totalScoreExp),
                    Exp.cond(
                        Exp.lt(Exp.var("total"), Exp.val(70)), Exp.val("C"),
                        Exp.le(Exp.var("total"), Exp.val(85)), Exp.val("B"),
                        Exp.gt(Exp.var("total"), Exp.val(85)), Exp.val("A"),
                        Exp.unknown()));
Expression gradeExpression = Exp.build(gradeExp);

Exp minExp = ListExp.getByRank(ListReturnType.VALUE, Exp.Type.INT, Exp.val(0), Exp.listBin("tests"));   // min
Expression minExpression = Exp.build(minExp);

Exp maxExp = ListExp.getByRank(ListReturnType.VALUE, Exp.Type.INT, Exp.val(-1), Exp.listBin("tests"));   // max
Expression maxExpression = Exp.build(maxExp);

// update class bin with a random 1-10, and the grade bin using gradeExpOp
for (int i = 1; i <= 20; i++) {
    Key key = new Key(Namespace, Set, "id-"+i);
    int classwork = rand.nextInt(SCORE_RANGE)/5;
    Bin classBin = new Bin(new String("class"), classwork);
    
    // write gradeExp to the bin "grade"
    Operation gradeExpOp = ExpOperation.write("grade",
                                 gradeExpression,    
                                 ExpWriteFlags.DEFAULT);
    
    client.operate(wpolicy, key, Operation.put(classBin), gradeExpOp);
}
System.out.println("Updated class participation and computed grades.");;

// run a report for all students with id, grade, total, min, max, avg
// using total, min, max, and avg expressions defined above

Operation ops[] = { Operation.get("id"), 
                    Operation.get("grade"),
                    ExpOperation.read("total", totalScoreExpression, ExpReadFlags.DEFAULT),
                    ExpOperation.read("testMin", minExpression, ExpReadFlags.DEFAULT),
                    ExpOperation.read("testMax", maxExpression, ExpReadFlags.DEFAULT),
                    ExpOperation.read("testAvg", avgScoreExpression, ExpReadFlags.DEFAULT)
};

for (int i = 1; i <= 20; i++) {
    Key key = new Key(Namespace, Set, "id-"+i);
    Record record = client.operate(null, key, ops);
    System.out.format("key=%s bins=%s\n", key.userKey, record.bins);
}
```

> Test data populated.  
> Updated class participation and computed grades.  
> key=id-1 bins={id=1, grade=A, total=90, testMin=85, testMax=97, testAvg=90}  
> key=id-2 bins={id=2, grade=C, total=57, testMin=54, testMax=63, testAvg=57}  
> key=id-3 bins={id=3, grade=B, total=79, testMin=56, testMax=84, testAvg=72}  
> key=id-4 bins={id=4, grade=A, total=86, testMin=69, testMax=98, testAvg=80}  
> key=id-5 bins={id=5, grade=B, total=73, testMin=62, testMax=67, testAvg=64}  
> key=id-6 bins={id=6, grade=A, total=88, testMin=62, testMax=92, testAvg=79}  
> key=id-7 bins={id=7, grade=A, total=88, testMin=76, testMax=96, testAvg=87}  
> key=id-8 bins={id=8, grade=B, total=82, testMin=60, testMax=99, testAvg=80}  
> key=id-9 bins={id=9, grade=B, total=80, testMin=59, testMax=98, testAvg=77}  
> key=id-10 bins={id=10, grade=C, total=69, testMin=52, testMax=87, testAvg=64}  
> key=id-11 bins={id=11, grade=C, total=54, testMin=50, testMax=55, testAvg=53}  
> key=id-12 bins={id=12, grade=C, total=61, testMin=55, testMax=63, testAvg=58}  
> key=id-13 bins={id=13, grade=B, total=81, testMin=70, testMax=89, testAvg=78}  
> key=id-14 bins={id=14, grade=B, total=70, testMin=60, testMax=84, testAvg=69}  
> key=id-15 bins={id=15, grade=B, total=84, testMin=77, testMax=87, testAvg=80}  
> key=id-16 bins={id=16, grade=A, total=90, testMin=70, testMax=92, testAvg=83}  
> key=id-17 bins={id=17, grade=C, total=61, testMin=50, testMax=57, testAvg=53}  
> key=id-18 bins={id=18, grade=B, total=77, testMin=55, testMax=83, testAvg=71}  
> key=id-19 bins={id=19, grade=B, total=79, testMin=58, testMax=95, testAvg=79}  
> key=id-20 bins={id=20, grade=B, total=81, testMin=54, testMax=84, testAvg=72}

You may view the state of the database and ensure correctness of the
output by running the following command in the terminal tab:

`aql -c "select * from test.expressions"`

# Using Expression Operations vs R-M-W or UDFs

Aerospike developers have multiple ways to perform a record oriented
read-write logic.

1.  Read record data to the client, modify, and write back ("R-M-W").
2.  Create a UDF for the logic and invoke it on the record.
3.  Use expression operations in a mulit-op request.

For read-write transactions, fetching the data to the client and writing
back is expensive and requires special care to ensure read-write
isolation. Lua UDFs can be difficult to implement, less flexible to
change, and can be slower. So it is generally beneficial to use
expression operations when possible.

Here is a suggested decision process:

1.  Use expression operations. However if expression operations cannot
    be used because the task, for example, requires unsupported features
    such as iterators and loops, then:
2.  Use client-side Read-Modify-Write (R-M-W) with version check if
    amount of data transfer as well as possibility of conflict due to
    concurrency is limited. Otherwise:
3.  Use UDFs if Lua server side programming model and performance meet
    the needs. Otherwise must use 2.

Note, Aerospike provides many ways to implement a given data task on one
or multiple records. To determine the optimal way for a given task, one
should consider and evaluate the options available including the various
execution modes (synchronous, asynchronous, background, etc).

# Usage Notes

-   Policy currently allows both the deprecated predExp and new
    `filterExp`, but they are mutually exclusive. If both are specified,
    only `filterExp` will be used and `predExp` will be ignored.

-   Errors during evaluation:

    -   Type match, bin existence, etc, can be checked using `cond` to
        avoid run time evaluation errors. `<pre>`{=html} Exp.cond(
        Exp.eq( // check if the bin is of type int Exp.binType("a"),
        Exp.val(ParticleType.INTEGER)), Exp.eq( // perform int
        comparison Exp.intBin("a"), Exp.val(1)), Exp.val(false)); //
        default is false `</pre>`{=html}
    -   Filter expressions treat the final unknown value as false,
        whereas in operation expressions it results in an error.
    -   If appropriate, evaluation failure can be ignored while
        performing multiple `operate` operations by setting the flags
        argument in `ExpOperation.read` or `.write` to
        `ExpReadFlags.EVAL_NO_FAIL` or `ExpWriteFlags.EVAL_NO_FAIL`
        respectively.

-   Constructs like loops and iterators over record bins or CDT elements
    are not currently supported. General manipulation of data beyond
    what is available in the APIs also is not supported.

# Takeaways and Conclusion

The tutorial described expressions capabilities in Aerospike. It
explained the scope and syntax, and described the key components and
constructs. It provided code examples for how to work with expressions
in two client uses: filter expressions and operation expressions.

The enhanced capabilities in filtering expressions allow records to be
processed more efficiently by avoiding the need for more expensive
client or udf based processing. New capabilities indlude access to
metadata, bin data, powerful APIs, as well as enhanced arithmetic and
other operators.

Operation expressions can eliminate the need to read before update by
allowing read, processing for update, and update to happen on the server
side in the same request. This saves a round-trip and transfer of
potentially large data.

Expressions provide powerful capabilities; evaluate and use them if they
are suitable and provide better performance for your use case over UDFs
and client-side processing.

# Cleaning Up

Remove tutorial data and close connection.

``` java
truncateTestData();
client.close();
System.out.println("Removed tutorial data and closed server connection.");
```

> Removed tutorial data and closed server connection.

# Further Exploration and Resources

Here are some links for further exploration.

## Resources

-   Workshop video
    -   [Unleashing the Power of Expressions Workshop (Digital
        Summit 2021)](https://www.youtube.com/watch?v=ebRLnXvpWaI&list=PLGo1-Ya-AEQCdHtFeRpMEg6-1CLO-GI3G&index=8)
-   Docs
    -   [Aerospike Expressions
        Guide](https://docs.aerospike.com/docs/guide/expressions/)
    -   [Java Expression
        Classes](https://docs.aerospike.com/apidocs/java/com/aerospike/client/exp/package-frame.html)
    -   [Aerospike Documentation](https://docs.aerospike.com/docs/)
-   Related notebooks
    -   [Read-Write Transactions with R-M-W Pattern
        (Python)](../python/transactions_rmw_pattern.ipynb)
    -   [Implementing SQL Operations: SELECT](sql_select.ipynb),
    -   [Implementing SQL Operations: CREATE, UPDATE,
        DELETE](sql_updates.ipynb)
    -   [Working with Lists](java-working_with_lists.ipynb)
    -   [Working with Maps](java-working_with_maps.ipynb)
-   Aerospike Developer Hub
    -   [Java Developers
        Resources](https://developer.aerospike.com/java-developers)
-   Github repos
    -   [Java code
        examples](https://github.com/aerospike/aerospike-client-java/tree/master/examples/src/com/aerospike/examples)
    -   [Java
        Client](https://www.aerospike.com/docs/client/java/index.html)

## Explore Other Notebooks

Visit [Aerospike notebooks
repo](https://github.com/aerospike-examples/interactive-notebooks) to
run additional Aerospike notebooks. To run a different notebook,
download the notebook from the repo to your local machine, and then
click on File-\>Open in the notebook menu, and select Upload.
