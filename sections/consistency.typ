#import "../imports.typ":*

= Consistency
== Consistency Model: Distributed Data Store
+ Distributed across multiple nodes in a *raplicated* fassion
+ Each replica holds *a copy of the entire store*
+ Each process can access *one or several replicas*
+ Write operations to a replica   are *propogated* to other replicas

*Notation*:
+ $W_i (x)a$: Write by process $P_i in P$ to item $x$ with value $a$, ($x <- a$)
+ $R_i (x)b$: Read by process $P_i in P$ from item $x$ with a return value of $b$, ($b <- x$)

== Data-centric Consistency
=== Strict Consistency
+ Exclusive Ordered Writes
  - Given 2 concurrent writes on $x$, one must go first
+ Up-to-date Monotonic Reads
  - A read on $x$ returns the *most recent* write on $x$ *regardless of the use of replica* by the client
  - Subsequent reads on $x$ returns the same value or some later value, *regardless of the use of replica* by the client
+ Instant Visibility
  - A write by any processor needs to be seen instantaneously by all other processors
  - Impossible in distributed systems
    - Network latency prevents instant update
    - No perfectly synchronised physical clock

=== Linearisability (Strong Consistency)
+ Same goal as Strict Consistency
  + Exclusive Ordered Writes
  + Up-to-date Reads
  + Overlap: Operations can overlap
+ Linearsation: Operation should appear to *take effect instantly* (update visible to all processes) *at some point* during its invocation (start) and reponse (end).
+ Compositional: *Separated linearisable histories* of objects can be *composed* in a linearisable history. 
It follows that for non-overlapping operations, if $A$ finished before $B$ starts (in read time), $B$ should see the changes made in $A$.
#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 69, width: 60%),
)

In the figure, $R(x)0$ is contradictory since it is after $R(x)1$ after which $W(x)1$ has already taken place.

=== Sequential Consistency
+ Processes agree on a global order that retains the programme order for each process
  - If in $P_1$, the order is $<W(x)_1, R(x)_1>$, the global order cannot be $<R(x)_1, ..., W(x)_1>$
  - Does not guarantee real-time ordering. If $P_1$ writes $x <- 1$ and finishes, then $P_2$ reads $x$ two seconds later, it may see the old value. But it is accepted as long as *all processes* agree on the same history
+ Not compositional. 
#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 70, width: 60%),
)

We can see an example. We try to make a global order of the execution of the above schedule:
+ $W(x)_2 2 < W(x)_1 1$
  + $P_3$ programme order: $R(x)_3 2 < R(x)_3 1$
  + Read order: $W(x)_2 2 < R(x)_3 2 and W(x)_1 1 < R(x)_3 1$
  + $=> W(x)_1 2 < R(x)_3 2 < R(x)_3 1$
  + It is only possible when $W(x)_2 2 < W(x)_1 1$. Otherwise $W(x)1 < W(x)2 < R(x)2 < R(x)1$ is FALSE.
+ $W(x)_1 1 < W(x)_2 2$
  + $P_4$ programme order: $R(x)_4 1 < R(x)_4 1$
  + read order
+ Contradictory

== Client-centric Consistency
- Guarantees consistency for *SINGLE CLIENT*'s access to the data store. (client's own view)
- Does not guarantee consistency by multiple different clients (Unlike data-centric)
- Implemented by using version vectors to keep track read and write sets for each client
    - write set ($"WS"_i$): *Writes* performed by the client itself
    - read set ($"RS"_i$): *Writes* that are *visible* during client's *previous reads*

*The Algorithm*

*On Replica(Server) $R_i$*
#figure(
  kind: "algorithm",
  supplement: [Algorithm],

  pseudocode-list(booktabs: true, numbered-title: [
    ReplicaRead($"RS"_i$, $"WS"_i$, $C_i$)
  ])[
    + *if* (strategy = "ReadMyWrite") *then*
      + *while* $"VV"_k < "WS"_i$ *do* *wait*; *end*
    + *else if* (strategy = "MonotinicReads") *then*
      + *while* $"VV"_k < "RS"_i$ *do* *wait*; *end*
    + *end*
    + $"val" <- "doRead"()$;
    + $C_i$.reply($"val"$, $"VV"_k$);
  ]
)

#figure(
  kind: "algorithm",
  supplement: [Algorithm],

  pseudocode-list(booktabs: true, numbered-title: [
    ReplicaWrite($"RS"_i$, $"WS"_i$, $C_i$)
  ])[
    + *if* (strategy = "MonotinicWrites") *then*
      + *while* $"VV"_k < "WS"_i$ *do* *wait*; *end*
    + *else if* (strategy = "WritesFollowReads") *then*
      + *while* $"VV"_k < "RS"_i$ *wait*; *end*
    + *end*
    + $"val" <- "doRead"()$;
    + $C_i$.reply($"val"$, $"VV"_k$);
  ]
)

*On Client*

Note that client read and write blocks until it receives the reply from the replica $R_k$ with (the replica's) version vector $"VV"_k$.
#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  
  pseudocode-list(booktabs: true, numbered-title:[
      ClientRead($"RS"_i$, $"WS"_i$, $R_k$: Replica)   
  ])[
    + $R_k$.requestRead($"RS"_i$, $"WS"_i$);
    + $"VV"_k <- R_k$.recv();
    + $"RS"_i <- max("VV"_k, "RS"_i)$;
  ]
)

#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  
  pseudocode-list(booktabs: true, numbered-title:[
      ClientWrite($"RS"_i$, $"WS"_i$, $R_k$: Replica)   
  ])[
    + $R_k$.requestWrite($"RS"_i$, $"WS"_i$);
    + $"VV"_k <- R_k$.recv();
    + $"WS"_i <- max("VV"_k, "WS"_i)$;
  ]
)

=== Read Your Writes (RYW)
If the client write data item $x$ on replica $R_k$, any subsequent reads *by client $C$ on replica $R_k$* will see (return at least as recent as) the write.

*Read($"RS"_i$, $"WS"_i$)*: Wait until $"VV"_k >= "WS"_i$.

Wait until the replica $R_k$ has seen client's write $"WS"_i$.

=== Monotonic Reads (MR)
If the client $C$ reads data item "x" on replica $R_k$, any subsequent reads *by client $C$ on replica $R_k$* will return at least as recent as the read.

*Read($"RS"_i$, $"WS"_i$)*: Wait until $"VV"_k >= "RS"_i$.

Wait until the replica $R_k$ has more (or same) information as the client's reads $"RS"_i$

=== Monotonic Writes (MR)

*Write($"RS"_i$, $"WS"_i$)*: Wait until $"VV"_k >= "WS"_i$.
Wait until the replica $R_k$ has registered the client's writes $"WS"_i$.

=== Writes Follow Reads (WFR)
*Write($"RS"_i$, $"WS"_i$)*: Wait until $"VV"_k >= "RS"_i$
Wait until the replica $R_k$ has seen all the reads from the client's write

== Consistency Protocol
=== Primary-based Protocols
Writes are managed by a *single primary replica*

==== Primary-backup Remote-write

+ All *Writes* are forwarded to *the* primary replica
  - Blocking write protocol is used.
+ Reads can be carried out locally
+ On failure, leader election

*Features*
- $arrow.b$ Bad write performance: blocking write protocol
  - non-blocking alternative: if some replicas fail during update, read-your-writes consistency is not guaranteed
- $arrow.t$ Easy to implement sequential consistency
  - Primary sends write operations to replicas using *FIFO-ordered view-synchronous atomic multicast*
- Implements linearisability if read requests are also forwarded to the primary

#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 91, width: 60%)
)

==== Primary-backup Local-write
E.g. Used in distributed file systems
+ Primary migrates to the replica that is writing
+ Successive writing are carries out locally
+ Replicas are updated using a non-blocking protocol
  - Optimises for several writes (only propagate after the last write of the client)
  - All replicas receives update in the same order? -> Sequential consistency
Q: What kind of consistency does this provide?

#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 94, width: 60%),
)

=== Replicated-write Protocols
==== Active Replication Protocol
Clients broadcast each operation to *all* replicas and operations are carried out in the same order
  - in *Total-FIFO-ordered multicast*
  - *Sender waits* until the multicast message is delivered back to the client
*Consistency*
- Multicasts read and writes: linearisability
- Multicasts only writes: *sequential consistency*
  - Read returns the current value of the local copy
==== Quorum-Based Protocols
Clients must get replies from a *quorum* ($N_R$, $N_W$) of $N$ replicas before reading or writing
- Avoid write-write conflict: $N_R > N/2$
- Avoid read-write conflict: $N_R + N_W > N$

To implement linearisability:
- use *majority quorums* for reading and writing: $N_R > N/2$, $N_W > N/2$
- use *version vectors* to achieve ordered writes according to their real-time order
  - Writes must read first to learn the highest version and potential siblings
- Perform *read-repair* to achieve up-to-date monotonic reads
  - read operations must write to update stale replicas

*Read Repair*
#figure(
  image("../slides/3-distributed-shared-data.pdf", page: 99, width: 60%),
)

===== Quorum Write
+ Read Phase
  - Send read requests to *ALL* (or $N_R$) replicas
  - Await replies from $N_R$ replicas
  - Learn the highest version among the replicas, merge siblings if needed
+ Write Phase
  - Send write requests (containing the version learnt) to all (or $N_W$) replicas
    - If we send to $N_W$ replicas, the remaining replicas are updated in the background
  - Await acknowledges from $N_W$ replicas
  - Write is complete and return to the user

===== Quorum Read
+ Read Phase
  - Send read requests to *ALL* (or $N_R$) replicas
  - Await replies from $N_R$ replicas
  - If version numbers are the same, return the value to the user
+ Write Phase (Read Repair)
  - Send write requests to *ALL* (or outdated) replicas
    - The requests contains the largest version number and associated up-to-data value
  - Await acknowledgement from *$N_W$* (or only updated) replicas
  - Return the value to the user