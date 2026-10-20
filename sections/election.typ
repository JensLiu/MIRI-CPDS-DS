= Election Algorithms
Leader election algorithms ensure that an election includes with *all processes* agreeing on a *unique coordinator*.

Just pick one, WLOG, choose the one with largest identifier. (identifiers must be unique and totally ordered)

The following algorithms *CANNOT* tolerate network partition

*Properties*
- *Safety*: a participant is either *non-decided* or *decided* process with the largest ID and this decision is consistent with all non-crashing processes
- *Liveness*: all processes participate and eventually either decide on a elected coordinator or crash
== Bully Algorithm
*Assume*:
- *Synchronous System*: can use timeout to detect process failure
- *Strongly Connected Topology*: exists a communication path between any two 
- *Reliable Communication*: message delivery is reliable, no message drop
- *Full Knowledge of IDs*: each process know the ID of every other processes. (But doesn't know which one is down)
- *Simultaneity*: multiple processes may start elections concurrently
- *Crashed process cannot restart during an ongoing election*, otherwise the safety property will be violated

*Algorithm*
+ Some $P_i$ starts election
+ $P_i$ Send election message to all processes with *higher ID*
  - $forall j > i: "Send"(P_j, "Election")$
  - _$P_i$: "Hey, are you greater than me"?_
+ $P_j$ receives election message, reply $"OK"$ and starts another election (send messages to processes with higher ID) UNLESS it has already begun an election
  - NOTE: Replying OK and starting election message *simultaneously*
  - If $P_j$ receives an election message, it must come from $P_k: k < j$.
  - _$P_k$: "Are you greater than me?"_
  - _$P_j$: "Yes, shut up"_
+ $P_i$ receives $"OK"$, drop out of the election and wait for the $"Coordinator"$ message
+ $P_i$ does not receive any $"OK"$ messages before timeout (synchronous system), it wins and sends the coordinator message to the rest of the processes
  - _$P_i$: "Are you greater than me? No one?"_
  - _$P_i$: "I'm the leader now"_

#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 54, width: 60%),
)

== Chang and Robert's Ring Algorithm
*Assume*:
- *Asynchronous System*: not using latencies to detect process failures
- *Partial Knowledge of IDs*: Each process only knows its *successor* in the ring.
- *Process Cannot Fail During Election*: Otherwise liveness property is violated.
- Clockwise election
*Algorithm*
- Each process is marked as *non-participant*
- Every time a process sends/forwards a message, it becomes a *participant*
- $P_i$ sends an election message $E_i$ with its own ID ($i$) to its successor and become a *participant*
- $P_j$ receives the Election message $E_i$ (idea: forward $E_max(i, j)$)
  - $i > j$: forward $E_i$ to its successor (unconditionally forwarding larger election IDs)
  - $i < j$: (I'm larger, choose me!)
    - $not "Participated"(P_j) =>$: send *$E_j$* to its successor (notice it changed the candidate to itself)
    - $"Participated"(P_j) => $: don't forward
  - *$i = j$*: (No one's larger than me)  *$P_j$ wins*, send the coordinator message $C_i$ to its successor
- $P_j$ receives the Coordinator message $C_i$ ($i != j$), forward it to its successor and become a *non-participant*
- When the coordinator message reaches the coordinator, the leader discards the message, the election is over.
== Enhanced Ring Algorithm
Each process must know *all nodes* in the ring\
Each process add its ID to the election message.\
When the message get back to the *Initiator*, choose the highest-ID process as the coordinator

*Algorithm*
+ $P$ sends *Election message* to its *closest alive successor* (sequentially poll successors until one responds)
  - Question: are we still assuming asynchronous systems? because if we did, we cannot distinguish between a failed process and delayed message and we cannot rely on timeouts
+ At each step, *each process adds its ID to the list in the messages*
+ When the message get back to the *initiator* (the *FIRST* process that *detects its ID*), it elects as coordinator the process with the *highest ID* and sends a Coordinator message with that ID
  - Tricky: If $P_2$ first starts the election, it could be that when message reaches $P_1$ as $[P_2, P_3, P_4, P_1]$, $P_2$ crashes and the message is directly sent to $P_3$. Then $P_3$ became the first process to detect its own ID. Then it send the coordinator message.
+ *Each process add its ID to the message* when passing the Coordinator message
+ When the Coordinator message goes back to the initiator, if *the elected process is in the ID list*, we are done. Otherwise, *reinitiate the election*.
