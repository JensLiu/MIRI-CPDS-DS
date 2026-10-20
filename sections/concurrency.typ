= Concurrency

*Conflicting Operations*: (when two transaction's lifespan overlaps)\
Two transactions are conflicting if their effect depends on the order in which they execute
- *Read-Write Conflict*: A transactions is reading a value another transaction is updating
- *Write-Write Conflict*: Two transaction both attempt to update the same value

*Strict Execution of Transactions* (Avoid dirty read and premature writes)\
Both *read and write* operations on an object must be *delayed* until *earlier transactions* that *wrote* on that object has been *committed or aborted*

== Serially Equivalent
- two transactions are serially equivalent when *all pairs* of *conflicting operation* are executed in the *same order* at *all shared objects*.
- i.e. *the same transaction always operates first* (when executing *conflicting operations*)

== Strict Two-phase Locking
*Transaction Ordering*: No predefined order of the transaction
- *Serial Equivalence*: A transaction is not allowed new locks after it has released a lock
- *Strict Execution*: Lock must be held until the transaction commits or aborts

*Increase Concurrency*: Use read and write lock
- *Read lock*: if *no writer*, multiple transactions can take read lock
- *Write lock*: if *no reader nor writer*, one transaction can take the write lock
- Allow read lock to be *promoted* to write lock when there is *only one reader*, namely the read lock holder

*Algorithm*
- On read/write operation
  - Object not locked: lock the object and proceed
  - Object locked
    - Conflicting Lock: wait until it's unlocked
    - Non-conflicting lock: share the lock (e.g. multiple read lock)
  - Object lock promotion (e.g. read-to-write lock promotion)
    - Can promote: promote and proceed
    - Cannot promote, prevented by conflicting lock, wait until unlocked
- On commit/abort: Unlock all object for this transaction

=== Deadlock Detection
*Wait-for Graph*
- $A -> B$: A waits for B
- Check for deadlock when
  - Each time an edge is added (i.e. a lock is taken)
  - May be less frequently to avoid overhead
- Deadlock Resolution
  - Abort transaction involved in the cycle
    - Which to abort: age of transaction, number of cycles (in deadlock) the transaction is involved in, etc.
  - Lock timeouts
    - A taken lock is made vulnerable after a timeout
    - Lock is broke if any other transacting is waiting on it
    - Transaction with broken lock is aborted
    - $arrow.b$ unnecessary aborts. How to choose timeout?
#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 23, width: 60%),
)

== Timestamp Ordering
Each transaction has a unique timestamp 
- assigned *when the transaction starts*
- defines its position in the sequence of transactions

Each Object $x$ keeps
- Write timestamp for its *committed* value: $"wts"(x)$
  - Uncommitted transactions keeps a tentative value and $"wts"(x)$ is kept unchanged
- Read timestamps (highest): $"rts"(x)$
- Pending read and tentative write ops with their corresponding timestamps

*Validation*
- *Each operation is validated* when they are *performed*
- If a transaction made it to the commit stage, we should always commit because each of its operations is legal

=== Write Validity
When transaction $T$ wants to write to $x$, it is valid only if\
*$x$ was last read or written by the earlier transactions (and can be written by $T$ as well)* 

We then *add this write to tentative versions*, update the version if it already exists

$
  "ts"(T) >= "rts"(x) and "ts"(T) > "wts"(x)
$
Otherwise we would have $"ts"(T) <= "wts"(x) or "ts"(T) < "rts"(x)$
- $"ts"(T) < "wts"(x)$: We overwrite a "future" value written by later transactions (because we predefine the order when the transaction starts)
- *$"ts"(T) < "rts"(w)$*: We "altered the history" because a "future" transaction read the value we are overwriting and thinks no one altered it.
- $"ts"(T) = "wts"(w)$: not possible because $T$ is not committed 

#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 28, width: 60%),
)

In the fugure above, (a)-(c) shows $"wts"(x) < "ts"(T_3)$, while (d) shows $"wts"(x) > "ts"(T_3)$, which is unacceptable.

=== Read Validity
When transaction $T$ wants to read from $x$, it is valid only if $x$ is *last written by earlier transactions* (No later/future transaction write to it).
$
  "ts"(T) > "wts"(x)
$
Note that no version of $"ts"(T) = "wts"(x)$ because the write for uncommitted $T$ is stored as *tentative version* of the value and *not committed*

*Read most recent version*: ($max{t: "wts"(x) <= t < "ts"(T)$})
+ It is a *tentative version*
  - Pend until this tentative version is committed, i.e. the (logically) earlier transaction completes
  - Scenario: It may happen that some tentative versions is newer than the committed version, we need to read the latest version
+ It is *committed*
  - Read and update timestamp to $"ts"(x) = max{"rts"(x), "ts"(T)}$
+ *$T$ already have a transitive version*, use it (Read your writes)


== Optimistic Concurrency Control
*Phases*
- *Working Phase*: Operation proceeds, write to a private workspace
  - Keep tentative versions of each object it updates
  - Keep read and write set of the transaction
  - Read operations are directed to the tentative versions (if exists) or committed ones
  - Write operations are directed only to tentative versions
- *Validation Phase*: Check if it has conflicted with concurrent transactions
  - A transaction is *given a sequence number when entering validation phase*
  - NOTE: Different from timestamp ordering where the sequence number is given at the start of the transaction.
- *Update Phase*: Tentative versions of any write operations are committed to the database

== Backward Validation
Check if the validating transaction ($T_v$) read *stale* data.

Compare the *read set* of $T_v$ with *write set* of transactions *committed while $T_v$ is working*

NOTE: *DO NOT* compare *ABORTED* transactions.

$
  "RS"(T_v) inter (union.big_(T_"start" < T_i <= T_"end" \ and "Committed"(T_i)) "WS"(T_i)) = emptyset 
  
$

== Forward Validation
Check if the validating transaction ($T_v$) *alters active (UNCOMMITTED) transactions' view of the data*
$
  "WS"(T_v) inter (union.big_(T_i in "Active") "RS"(T_i)) = emptyset
$
*$arrow.t$ More flexible conflict resolution*
  - Abort the committing transaction
  - Abort the conflicting active transactions
  - Let conflicting transactions finish and try again (they may abort)
  - ...
*$arrow.b$ Dynamic read sets when validating*
  - *Block read operations* of active transactions on *contended object* while in *validation and update phase*

= Distributed Transactions
Transactions can access objects managed by multiple servers
- For each transaction, one server can act as the coordinator
  - Coordinator is responsible for opening and closing (commit/abort) of a transaction
- Each server accessed by a transaction is a participant (the coordinator can also be the participant in the same transaction)
== Distributed Commit
=== Two-Phase Commit Protocol
Abort whenever *any* participant decides to abort.\
+ Coordinator send *vote-request* message to all participants (including itself)
  - Coordinator *blocked* on *WAIT* state to *collect votes* from every participants (including itself)
    - On timeout, ask the participant to send the vote again; if no response, abort
+ Participants reply 
  - *vote-abort* if they cannot commit locally
    - Directly *abort*
  - *vote-commit* if they can commit locally
    - If it votes commit, it must *ensure* that it will *eventually* be able to carry out the commit [write-ahead log perhaps?]
    - *Blocked* on *READY* state to see if the coordinator decides to abort
      - On timeout
        - ask the coordinator to resend the global decision
        - query other participants about their state 
          - if any of them decides to abort, we should abort
          - if no response or all participants blocked on *READY*, we cannot decide
+ Coordinator collect *all votes* (including itself), if 
  - *ANY* says abort, send *global-abort*
  - otherwise, *ALL* says commit, send *global-commit*
+ Participants commit or abort according to the message
  - optionally send acknowledgement when done

#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 46, width: 60%),
)
In the above figure, the coordinator state machine is on the bottom left, while the participant state machine is on the bottom right.

=== Other Protocols
*Three-Phase Commit*: avoids blocking problem but adds latencies and does not tolerate network partitions. $->$ Often not applied in practive.

*Paxos Commit*: 2PC on top of Paxos

== Distributed Concurrency Control
Schedule concurrent transactions to preserve serial equivalence.
- Each server is responsible for the concurrency control of *its own objects*
- All Servers must agree on *the same order of transactions* to preserve serial equivalence (recall that serial equivalence means that if $T$ is before $U$ in their access to objects in one server, then *all server* should have $T$ before $U$).
=== Strict Two-Phase Locking (Distributed)
For each object, locks are *maintained locally* on its server\
Locks are held until the transaction is committed or aborted at *all servers involved*.
==== Distributed Deadlock Detection
===== Centralised Detection
A server builds (merges) a *global wait-for graph* from local wait-for graphs
- Looks for cycles in the global wait-for graph
- Tells servers which transaction to abort
*Cons*
- $arrow.b$ Poor scalability and fault tolerance
- $arrow.b$ How often should we *collect* local wait-for graphs?
  - cost of frequent transmission is high
  - Less frequent transaction implies deadlock may take longer to detect

#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 54, width: 60%),
)

===== Edge Chasing
When we want to detect a specific dead lock, we send a *probe* message to the next "site" following the dependencies.
$
  "Probe"(underbrace(P_"initiator"\, P_"sender", "current site"), underbrace(P_"receiver", "next site"))
$
If the probe message arrive to the same site and $P_"initiator" = P_"receiver"$, we have a deadlock. The following figure shows a deadlock detection process. $"Probe"(1,6,8)$ is sent from $P_6 in S_3$ to $P_8 in S_2$. And when the probe message get back to site $S_1$, we have $P_"initiator" = P_"receiver" = 1$.

#figure(
  image("../edge-chasing.png", width: 70%) 
)
=== Timestamp Ordering (Distributed)
The coordinator of a transaction assigns it a *globally unique timestamp* when it starts.
As different servers can act as coordinators, they must agree on the order of the timestamp they generate (e.g. as $("ts"_"local", "ServerID")$).

Locally to each server, the protocol acts the same

=== Optimistic Concurrency Control (Distributed)
A transaction is validated by a *collection of servers* of the object it accessed.

Problem: Different servers may serialise the same set of transactions in different orders.

*Backward Validation (Graph Validation)*
+ Perform *local validation*
+ *check globally* if *the combination of the ordering* is *serialisable*
  - Transaction being validated is not involved in a cycle
  - e.g. $T_1 -> T_2$ on server A but $T_2 -> T_1$ on server B
*Forward Validation (Global Sequencing)*
- Coordinator assigns to the transaction a *global sequence number* at the start of validation
- All servers *must* serialise in this specific order, otherwise abort.