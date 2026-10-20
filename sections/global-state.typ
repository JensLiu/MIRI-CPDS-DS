= Global States
== Basic Concepts
- *History of Process*: The sequence of events the occour at a process $h_i = <e_i^1, e_i^2, ...>$.
- *State of process*: The *finite prefix* of the history after $k$ events, i.e. $s_i^k = <e_i^1, e_i^2, ..., e_i^k>$.
- *Global history*: The union of individual processes $H = union.big_i h_i$.
- *Cut*: The global history up to a specific event in each process history.
  - union of prefixes of process histories
  - e.g. $S = <s_1^k_1, s_2^k_2, s_3^k_3, ..., s_N^k_N>$ where $s_i^k = <e_i^1, ..., e_i^k>$.
  - Consistent cut: for each event, it contains all events that *happen-before*.
- *Run*: a *total ordering* of all events in a global history consistent with each *local history* (maintain $forall i: e_i^k_1 < e_i^k_2 <=> k_1 < k_2$).

== Linearisation
A run consistant with the *happen-before relation* (message passing, transitivity)

*Reachability of States*: State $S^prime$ is reachable from $S$ if and only if there is a linearisation passing through $s$ and then $s^prime$.
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 29, width: 60%),
)

In the above figure, we have 
- a run of ${e_1^1, e_1^2, ...}$ that is consistant with the happen-before relationship as listed on the top, and
- a potential state transition $S_0 -> S_1 -> ... -> S_6$ as listed on the left.
  - Note that each state transition only alters one column, e.g. $S_0 -> S_1$ only alters $s_1^0 -> s_1^1$, which executes event $e_1^1$,

== Chandy-Lamport Shapshot Algorithm (Global State)
An algorithm that allows each processor to take *individual snapshots* s.t. when the snapshot is later stitched together by *some external* to the algorithm, it would be consistent.

It does not care how to put individual snapshots together.

- Processes may continue to their execution while taking the snapshot
- Any process may initiate a snapshot at any time (decentralised algorithm  )
- Separate snapshots may be initiated concurrently (tagged with a marker message)

*Assume*:
- *Reliable* processes and channels
- *Unidirection channels* $forall i != j: C_(i,j) <=> C_(j, i) in "Channels"$
- *FIFO channels*: Arrives in sending order! 
  - no message crossing, e.g. $P_i$ send $(m_1, m_2)$ and $P_j$ receives $(m_2, m_1)$.
- *Strongly connected topology* 
  - does not require fully connected
  - the algorithm *flood* through the network (since the receiving sends marker to its neighbours acting as somehow another "initiator" if its neighbour hasn't seen a message).

When the algorithm terminates, *everyone* would have sent *everyone* a marker message.

*Algorithm for Initiator Kick-start $i$ (On Recording Request)*
+ Record its own state $S_i^n (P_i)$ (All events on $P_i$ so far)
+ Send a special marker on *every* outgoing channels: $forall j: "send"(C_(i,j), "Marker")$
+ Start recording messages on *each incoming channels* until each of its incoming channels has received a marker
  - $forall k: "receive"(C_(k, i), "Marker")$

*Algorithm for Receiver AND Initiator $j$ (On Receiving a Marker from $C_(i,j)$)*
- *$P_j$ has not saved its state*
  + Record its own state $S_j^m (P_j)$.
  + *Mark the channel $C_(i, j)$ as empty* (because we saved the states)
    - If we receive the marker message, it means that *ALL* messages before the snapshot has arrived (on this specific channel)
    - If we receive any messages from this "empty" channel, it must be in the "future" (FIFO ordering), we exclude this from our snapshot
    - This marks the *end of snapshot of the current $C_(i, j)$ channel*, now we want to take snapshot of other channels
  + Send special marker on *every outgoing* channel: $forall k: "send"(C_(j,k), "Marker")$
    - This includes the channel $C_(j, i)$ to reply to process $P_i$
  + Start *recording* message over *OTHER incoming channels* until each of the incoming channels have received a marker.
      - $forall k != j: "receive"(C_(k, j), "Marker")$
      - The state of channel $C_(k,j)$ is the sequence of all messages from the time $P_j$ records its state until the time marker arrive from $P_k$
- *$P_j$ has saved its state*
  + $P_j$ stop recording on $C_(i,j)$ and set $C_(i,j)$s final state as the sequence of all incoming messages that arrive on $C_(i,j)$ since recording begin

  
*Example*
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 35, width: 60%),
)

The above figure describes a simple scenario for channels $C_(i,j)$ and $C_(j,i)$.
- *For $P_i$*
  + $P_i$ record its state $S_i^n (P_i)$ (in this case it would be $<\$1000, 0>$)
  + $P_i$ send marker to $P_j$ through $C_(i,j)$ *It now has seen A MARKER * (because it sends one)
  + $P_i$ start recording messages: $S_i^n = emptyset$
    + $P_i$ receives $"msg"_1 = ("order" 10, \$100)$, records it, now $S_i^n (C_(j, i)) = ("msg"_1)$
    + $P_i$ receives marker from $P_j$, since it has seen a marker, stop recording
      - The final state for $C_(j,i)$: $S_i^n (C_(j, i)) = ("msg"_1)$.
  + Terminates since it has seen markers on each of its incoming channels
- *For $P_j$*
  + $P_j$ send message $"msg"_1 = ("order" 10, \$100)$ to $P_i$ through $C_(j,i)$.
  + $P_j$ receives a marker from $P_i$, it is the *FIRST TIME* $P_j$ has seen a marker from $C_(i,j)$ hence $S_j^m = emptyset$
  + $P_j$ send a marker to each of its channels, in this case: $C_(j,i)$.
  + Terminates since it has seen markers on each of its incoming channels

#grid(
  columns: 2,
  [
    #figure(
      image("../slides/2-distributed-algorithms.pdf", page: 36),
    ) 
  ],[
    #figure(
      image("../slides/2-distributed-algorithms.pdf", page: 37),
    )    
  ]
)

== Global State Predicates
=== State Predicate
- A predicate become true and ti remains true for *all reachable states*
- If a stable predicate is true in a snapshot then it is also true in the execution

=== Not-stable
*Lattice*
- Consistent global states form a *lattice* with reachability relation between states
- The lattice shows all the linearisation corresponding to a global history
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 42, width: 60%),
)

- A predicate can evaluate true and then become false in some *reachable state*
- Category
  - Possibly $Phi$
    - $exists$ consistent global state $S$ as part of a linearisation such that $Phi(S) = T$
    - Check through all consistent global states of the lattice to check whether $Phi$ is true for all of them
      - $exists S in "Lattice": Phi(S) = T$
  - Definitely $Phi$
    - $forall$ linearisation pass through some consistent global state $S$ such that $Phi(S) = T$
    - Step through all the paths *from the initial to the final* state of the lattice to check if *all of them* include a consistent global state for which $Phi$ is true
      - $forall p in "Path": exists S in p: Phi(p) = T$
  - Never $Phi$
    - $not exists$ linearisation pass though *ANY* global state $S$ such that $Phi(S) = T$
    - Step through all the consistent global states of the lattice to check whether $Phi$ is false for all of them
