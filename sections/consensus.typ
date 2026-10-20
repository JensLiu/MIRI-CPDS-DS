== Consensus
We want to tolerate $f$ failures
=== Unreliable Communication (Two-army Problem)
With unreliable communication, agreemet between two processes cannot be guaranteed
=== Crash-faulty Processes, Synchronous System 
*Assume*: *Crash-faulty* processes, *reliable* communication, *synchronous* system.\
*Dolev & Strong's Algorithm* \
Algorithm has (f+1) rounds
+ Each process propose a value
+ From round 1 to f+1, each process
  + multicast *new* values 
    - new value: not sent in the previous round
    - in the first round, send the proposed value
  + collect from all other processes and mark *new* values (to send in the next round)
  + A round terminates when values for all processes are collected or by timeout (based on mi message latency)
+ Each process decide against collected values
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 103, width: 60%),
)

=== Byzantine-faulty (Lying) Processes, Synchronous System
*Assume* *Byzantine-faulty* processes, reliable communication, *synchronous* system\
We restrict the problem to *ONE* general sending his value to others:\
A *commanding general* send must send a message to his n-1 *lieutenants*\
*Interactive Consistency Requirements*
- *IC1 (Agreement)*: All *loyal* lieutenant obey the same order (reach agreement)
- *IC2 (Validity)*: *If the commander is loyal*, then all loyal lieutenant obey the order he sends
  - If the commander is *NOT loyal*, we only need to reach consensus, but the value doesn't matter (special value $bot$ is also considered valid if no majority)
  - From previous exams:  When the commander is a traitor, the loyal lieutenants can agree an undefined value $bot$.

*Impossible Result*: with 3 processes, cannot traitor even 1 traitor:\
Because we cannot distinguish if the commander is the traitor or the other lieutenant is the traitor. 
- Imagine Lieutenant *L1* is loyal and
  - *C -> L1*: attack
  - *L1 -> L2*: attack
  - *L2 -> L1*: retrieve
- Possibilities
  + *C* is the traitor: *C -> L1 (Attack)*, *C -> L2 (Retrieve)*
  + *L2* is the traitor: *C -> L2 (Attack)*, *L1 -> L2 (Attack)*, *L2 -> L1 (Retrieve)*

*Bounds*
- *Without Crypto*: Need $N > 3m + 1$ processes to tolerate $m$ traitors
 // - Need the majority of loyal nodes ($2m+1$) to overvote traitors ($m$)
 // - $N = underbrace(m ("Liars"), "Liars") + underbrace(underbrace(m("Neuralised Honest"), "Cancelled (by the liars)") + underbrace(m+1 ("tie-breakers"), "Deciders"), "Loyals")$
// - *With Signitures/Crypto*: Need $N > m$ processes if we only want agreement among lieutenant, need $N > m + 1$ if we want

==== Oral Message Algorithm (OM) !!!!
Cross-examining witnesses by exausively ask everyone what the commander told then and what everyone told everyone.\
Tolerate at most $m$ traitors with at least *$3m+1$ participants*\
*Assumption*
- Sent messages are correctly delivered (no corruption)
- The absence of message can be detected
- The receiver of a message knows who sends it

In the following figure, lieutenant $1$ wants to know what the commander told him. He build a graph of every possible message flow from the commander ($C$) to himself ($1$).\
And this process is repeated for every lieutenant during the recursion (this is just a local view of lieutenant $1$).
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 114, width: 60%),
)

*Assume*:
+ *Fault Tolerance*: At most $m$ unreachable or illoyal participants
+ *Network*:
  + No message loss
  + The receiver knows the sender of the message
+ *Timing*: Absence of a message can be detected
*Algorithm* (Recursive):\
*$"OM"(n, t), t > 0$*:
+ The commander send its value to every lieutenant
+ For each lieutenant $i$, let $v_i$ be the value received from his commander
  - $i$ then act as a commander in $"OM"(n-1, t-1)$ in which he send his own $v_i$ to every *other* participants.
+ $forall i, j (i != j): $ let $v_j$ be the value in which lieutenant $i$ received from $j$ in step $"OM"(n-1, t-1)$
  - $i$ choose $"majority"(v_1, ..., v_(n-1))$.

The following figure shows how consensus is reached (2 traitors)
- In the green box, it shows how $"L1"$ determined determines what its commander $C$ say
  - Layers of indirection
    - $"OM"(2)$: Direct message from his commander $C$, but maybe $C$ is a traitor
    - $"OM"(1)$: One layer of indirection: What does $C$ say to each of other Lieutenants. But what if some lieutenant are traitors?
    - $"OM"(0)$: Two layers of indirection: What does each lieutenant says about each other lieutenant says about the commander
  - Values received
    - First column: The commander told me to attack
    - Second Column: 
      - L2 told me the commander told me to retrieve, and
      - All other lieutenants said L2 told them to retrieve
    - Third Column:
      - L3 told me to attack
      - L2-6 said L3 told them to retrieve and L6 said otherwise
    - ...
  - L1 needs to decide what each lieutenant said about the commander
- The cluster needs to decide what the commander
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 115, width: 60%),
)

=== Faulty Process, Asynchronous System
*NO* algorithm can *guarantee* to reach a consensus (even with one faulty process)\
Consensus can be reached with *some possibility*
==== Fault Masking + Basic Algorithm
- Assume failed process *always* recover and can *reintegrate* into the group.
- A round terminates when *every* expected messages is *received* (if a process is not responding, wait longer)

==== Failure Detectors + Synchronous Algorithm
- Determines which process has crashed
- A round terminates when
  - *every* expected message is received, or
  - *failure detector* suspect its sender's down
- Consensus with failure detectors requires that
  - Every faulty process is *permanently suspected* at least by some correct processes
  - At least a correct process is never suspected
  - Note: doesn't always hold for asynchronous systems but long enough for correct process to decide

==== PAXOS (Quorum)
*Assume*:
- Processes operate at *arbitrary speed*, *may crash*
- Restarted processes remember where in the process they were
- Messages take arbitrary long time to deliver, get lost or duplicated, but *NOT corrupted*

A single process can take multiple roles\
*Proposers*: Propose values to agree on a single one among all proposed values\
*Acceptors*: Decide whether to accept proposed values (act as the memory of the system)\
*Learners*: Check if any value has been chosen\

*Phase 1*
- Proposer: send *prepare* requests to *each acceptors* with seq. nr. $N$
  - "Please do not vote for any proposal number less than $N$"
- Acceptor: $N > P_"max"$:
  - Promise not to vote for any proposals with seq. nr. $< N$
    - $P_"max" <- max(P_"max", N)$
  - Reply with the highest-numbered *voted* proposal $("seq", "val")$
*Phase 2*
- Proposer: collect *promises* from the *majority* of acceptors
   + Choose the value with the highest-numbered proposal among the responses
   + If no proposal in the response, use its own value
   + send *accept* messages to acceptors
- Acceptor:
  + *Vote* for proposal *unless* it has *already promised* a number greater than $N$.
  + Acknowledge the proposer and leaners
*Phase 3*
+ When leaners collect notifications from a *majority of acceptors* for a given proposal, it becomes the final decision.
+ Each leaners may take action and inform the client about the outcome

*Best Case Message Count*
$6f+4 = underbrace((2f+1), "Propose") + underbrace((f+1), "Reply") + underbrace((2f+1), "Accept") + underbrace((f+1), "Reply")$