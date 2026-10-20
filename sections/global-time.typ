= Global Time
== Physical Clocks
+ Has an accuracy of milliseconds (ms)
+ Perfect synchronisation is not feasible
+ Cannot be used to order events

*Physical Clock Synchronisation*
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 7, width: 60%),
  caption: [Resynchronisation Interval: Problem Statement]
)

*Given*: 
+ maximum clock drift $rho$, and
+ maximum clock skew $delta$
*Want to find*: Resynchronisation interval $R$

Note that the rate for the "perfect" clock is $1$, i.e. the "perfect" clock does not drift.

Since the clock can drift faster or slower, we need to make sure the time difference between the *slowest* clock $R dot (1-rho)$ and the *fastest* clock $R dot (1+rho)$ does not diverge more then $delta$, hence we have the following relationship.
$
  Delta t = t_("fast") - t_("slow") = R dot ((1+rho)-(1-rho)) = 2 R rho <= delta \
  => R <= delta / (2 rho)
$

=== External Synchronisation: Christian's Algorithm 
Christian's Algorithm synchronises *nodes* ($C$, client) with a *UTC server* ($S$, Server) within a certain bound.
``
*Assume*:
+ Latency is symmetrical: $T_(C->S) = T_(S->C)$
*Given*:
+ Round-trip time (RTT): The time duration between the sending and receiving of the message from/to the client. In this figure, it's $T_2 - T_1$.
*Note*:
+ Here, we only interested in the time between when the server responds and the client receives the message, i.e. $T_(S->C) = "RTT" / 2$. (Since we assume that the latency is symmetric)
+ We cannot know when the server will receive the request and when it will respond. So the server response time $T_s^prime <= T_s <= T_s^(prime prime)$
+ The accuracy of the clinet is $plus.minus "RTT"/2 - "Min"$, which is $T_s - T_s^prime$ or $T_s - T_s^(prime prime)$. (Since $T_2 - T_s = "RTT"/2$, $T_s^(prime prime) - T_2 = "Min"$)
// #algorithm-figure(
//   "Christian's Algorithm", vstroke: .5pt + luma(200), {
//     import algorithmic:*
//     Procedure("ClientSync",("c: Client", "s: Server"),{
//           Comment[At $T_1$]
//           LineComment(Assign[$T_s$][s.Request()], [Blocking request])
//           Comment[At $T_2$]
//           LineComment(Assign[$T$][$T_s$ + $"RTT" / 2$], [RTT is given])
//           Return[T]
//     })
//     Procedure("ServerResponse", ("s: Server", "c: Client"), {
//         Assign[$"c"$][s.Receive()]
//         Assign[$T_s$][s.CurrentTime()]
//         LineComment($"c.Response"(T_s)$, [Respond with the current time of the server])
//     })
//   }
// )

=== Internal Synchronisation: Berkeley Algorithm
Berkeley's Algorithm synchronises nodes with one another within a certain bound.
#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 9, width: 60%),
)

*Assume*:
- We are given a tolerance of $delta$

*Algorithm*:
+ Master pulls each client at each $R$ interval
  - Master adapts them by considering RTT.
  - The slide did not count for RTT?
+ Master calculate a fault-tolerance average
  - Slaves lying outside the given bound is discarded
+ Master sends the adjustment to be made to each local clock

// #algorithm-figure(
//   "Berkeley's Algorithm", vstroke: .5pt + luma(200), {
//     import algorithmic:*
//     Procedure("MasterSync", ("C: [Slave]", [$delta$: Tolerance]), {
//       Assign[$T_c$][$forall c in "C": "c.Time()"$]
//       Assign[$T_c^*$][${t in T_c: t <= delta}$]
//       LineBreak
//       Assign[$"avg"$][$((sum T_c^*) + T_("self")) / abs(T_("bounded") + 1)$]
//       LineBreak
//       For($c in C$, {
//         $"c.response"("avg" - T_c [c])$
//       })
//     })
//     Procedure("Client", ("c: Client"), {
//       Assign[$Delta t$][c.Receive()]
//       Assign[$"c.time"$][$"c.time" + Delta t$]
//     })
//   }
// )

=== Time Stepping (TODO!)
TODO

== Logical Clocks
=== Happen-before Relation
We use the happen-before relation to capture *EVENTS* $E$.

- Events: happen in processes, e.g. sending and receiving of messages (The dots in the lines)
- Messages: Sent across processes (the arrows between dots)

*Assume*
- A set of processes $P$
- A set of *ALL* Events $E$
  - Events in process $P_i in P$: $E(P_i) subset E$
- Timestamp of Event $e in E$: $C(e)$
- Timestamp of message $m$: $"ts"(m)$

+ *Same process*: If $a, b in E(P_i)$ and $a$ comes before $b$, then $a -> b$
+ *Across processes*: If $a in E(P_i)$ is the sending event, and $b in E(P_j)$ ($i != j$) is the receiving events, then $a -> b$
+ *Transitivity*: $a->b and b->c => a->c$

Use timestamp to capture the happen-before relationship
$a->b => C(a) < C(b)$ where $C(e)$ is the timestamp to event $e$.

=== Lamport's Logical Clock

Lamport's Clock defines a *Partial Order* that is consistant with the _happen-before_ relation.

*If we want total order*, use Lamport's clock but add the process ID
$(C_i (a), i)$, so that\
$(C_i (a), i) < (C_j (b), j) <=> (C_i (a) > C_j (b)) or (C_i (a) = C_j (b) and i > j)$. 

*Given*
+ Each process $P_i in P$ has a counter $C_i$
+ This $C_i$ is used as the *timestamp* attached to *EVENTS* in $P_i$, namely $e in E(P_i) subset E$
+ $C(m)$: timestamp for the message

It does not guarantee causation:
- $a -> b => C(a) < C(b)$
- Not otherwise ($b$ and $a$ could be parallel)
  - $C(a) < C(b) => (b -> a) or (b || a)$

*Algorithm*
+ When an *EVENT* happens in $P_i$, increase the counter $C_i$
  - What do we mean by an *EVENT* happens in $P_i$
+ When $P_i$ sends a message $m$ to $P_j$, attach $C_i$ as the timestamp
  - $C(m) := "ts"(m) <- C_i$
+ When $P_i$ received a message $m$ from $P_j$
  - $C_i <- max(C(m) :="ts"(m), C_i) + 1$

#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 16, width: 60%),
)

=== Vector Clock
Vector Clock enhances Lamport's Clock to allow causality. The idea is to use a per-process vector to track at current process $P_i$, the version numbers of all processes $P_j$.

*Given* \
- a set of processes $P$
- a set of events $E$

*Construction* \
Each process $P_i in P$ maintains a *Vector Clock* $"VC"_i$ where
- An array of counters for each processes: $|"VC"_i| = |P|$
- $"VC"_i [j]$: Process $P_i$ tracks its progress from events coming from $P_j$
- $"VC"(m)$: The vectored timestamp for message $m$
- Comparison $"VC"(a) < "VC"(b)$:
  - iff ALL of their elements are "<=" and EXISTS some elements that is strictly "<"
  - $"VC"(a) < "VC"(b) <=> (forall k: "VC"(a) [k] <= "VC"(b) [k]) and (exists k: "VC"(a) [k] < "VC"(b) [k]) $
- Causality
  - $"VC"(a) < "VC"(b) <=> a -> b$
- Parallel
  - $not ("VC"(a) < "VC"(b) or "VC"(a) > "VC"(b)) => a || b$
  - We can simplify the above expression to:
    - $exists k_1, k_2: ("VC"(a)[k_1] < "VC"(b)[k_1]) and ("VC"(a)[k_2] > "VC"(b)[k_2]) => a || b$

*Algorithm*
- When $P_i$ send a message $m$
  + $"VC"_i [i] <- "VC"_i [i] + 1$
  + $"ts"(m) <- "VC"_i$
- When $P_i$ receives an message $m$ from $P_j$ (an event $e in E(P_i)$)
  + $forall k in 0..|P|: "VC"_i [k] <- max("VC"_i [k], "VC"(m))$
  + $"VC"_i [i] <- "VC"_i [i] + 1$

#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 21, width: 60%)
)

=== Dotted Version Vector ???!!!!
The version vectors are used in distributed systems for conflict resolution on concurrent update. The version vector consists of $(("id", "CausalPastMaxID"), "PresentEventID")$.

It keeps the "present event" (the dot) separate from the "causal past". Hence, if the "present event" of $X$ *is contained in* the "causal past" of $Y$, it means that $X -> Y$ ($Y$ is generated causally following $X$).

// In the original paper, The dotted version vector expressed as $((i, n), v)$ where $v$ is the traditional version vector the keeps track of *MULTIPLE* keys and $(i, n)$ is the dot.
// $
//   C[v] = union_((i, n) in v) {i_m: 1 <= m <= n} = union_((i, n) in v) {i_1, .., i_n} \
//   C[((i, n), v)] = {i_n} union C[v] = {i_n} union (union_((i, n) in v) {i_1, .., i_n})
// $
// where $i_n$ is the $n$-th event on node $i$.

In the slides, we are considering the version vectors for a *SINGLE* key, we simplified the notation
$
  C[(r, i, j)] = {r_j} union {r_1, ..., r_n}
$

*Construction*
- We have a set of replicas $R$ (as opposed to processes $P$)
- Items are the "entires" in each database, for example.
- Each replica $R_k$ (or $k$) keeps its own version vector for each item $"VV"_k = {((r_l, i_l), j_l) in bold("VV")}$ where $r_l$ is the replica, $i_l$ is the range of events ${1,...,i_l}$ and $j_l$ is the last event.
  - For example, $((c, 2), 4) in bold("VV")$ represents events in replica $c$: ${c_1, c_2} union {c_4}$, hence
  - ${(a, 2), (b, 1), ((c, 2), 4)} equiv {a_1, a_2, b_1, c_1, c_2, c_4} subset 2^bold(E)$
- Each incoming write (message) include a vector of *prior read items* (aka, causal context)
  - $"VV"_"inc"$
  - Intuition: This write to item $I_i$ is based on reading items $I_"context" subset 2^I$

*Order*

Causality $a -> b$:

*TODO*