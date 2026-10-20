= Multicast Communication
Types of multicase communication
+ *Multicast*: sned a message to a *process group*
+ *Reliable Multicast*: Deliver messages to *all* processes in a *(static) group* *or none* at all.
+ *Ordered Multicast*: Deliver messages while fulfilling ordering requirements
+ *Atomic Multicast*: Deliver messages to *all* processes in the *same order* in the presence of process failures *(dynamic process group)*

*Desired Properties for a CORRECT process*
- *Integrity*: Delivers every message *at MOST once* (filte duplicates)
- *Validity*: If $m$ is multicasted, the process will *eventually* deliver $m$.
- *Agreement*: If a correct process delivers $m$, then *all other correct processes in the group* will eventually deliver $m$,

== Reliable Multicast
This deal with the question: *Whether* a message can be delivered

=== Basic Reliable Multicast
*Assume* 
- Processes *do not fail*
- Processes *do not join/leave the group* (static group)

*Algorithm*\
*Sender* $p in P$
  + $p$ maintain a sequence number $S_p$
  + $p$ stores a copy of the ongoing message into a *History Buffer*
  + $p$ removes the copy when *everyone acknowledges the receipt*
    - Can keep a copy unboundedly long
Any *Receiver* $q in P$
  + records $L_q (p_i)$ the number of last message from sender $p_i in P$
  + $L_q (p_i)$ and $S_p$ ($S_p$ is from  the message) comparison
    - $S_p = L_q (p_i)  + 1$: new message
      - deliver the new message
      - reply *ack*
    - $S_p > L_q (p_i) + 1$: received missing messages
      - put message into the *Hold-back Queue*
      - reply *nack*, request a retransmission of missing messages
        - Retransmissions from the sender are also multicast messages
    - $S_p <= L_q (p_i)$: already received, discard (because of multicast, we receive retransmitted messages)

=== Scalable Reliable Multicast
Use missing messages are reported using *NACK* s
+ *Multicast NACK* when missing messages
+ Each process wait a random delay prior to sending NACK (to sniff if others sent it)
  - supress NACK if other process sent it
*Downside*
- $arrow.b$: Sender should keep messages in history buffer *forever* (since no ACK present and we cannot know if everyone acked it)
  - in practice, deleted after a certain period
- $arrow.b$ Setting timers to ensure only one NACK is hard

== Ordered Multicast
This deals with the question: *When* should the message be delivered\
Messages can arrive in different order at different nodes due to network latency
=== FIFO Ordering (within each process)
Messages sent *from the same process* are *delivered in the order* by all processes \
*Our per-process hold-back queue guarantees this*

=== Causal Ordering (between processes)
*Happen-before-related messages* are delivered in that order by all processes
- Causal order implies FIFO order (special case in the same process)

*Implemented using vector clock* (According to the solution of Q7, June 2021)
+ $P_i$ (Sender) increases its own $"VC"_"local" [i] += 1$ ONLY WHEN sending the message
  - DO NOT update $"VC"_"local" [i]$ when deliver the same message
  - The message in the sender is delivered immediately (according to the solution of Q7)
+ A message is *delivered only if all causally preceeding messages have already been delivered*
  - *$("VC"_"msg" [i] = "VC"_"local" [i] + 1) and (forall k != i: ("VC"_"msg" [k] <= "VC"_"local" [k]))$*
  - $i$: Sender PID
  - $"VC"_"msg" [k] (k != i)$ is the sender's view when sending the message
  - $"VC"_"local" [k] (k != i)$ is the receiver's view when the message is receives
  - Check after each delivery of the message (we may deliver multiple messages at a time from our hold-back queue)
+ Otherwise, postpone until the above-mentioned condition is met
+ $P_j$ (Receivers) increase their own $"VC"_"local" [i]$ ONLY after *delivering* the message
  - DO NOT update when received the message
  - UPDATE the *$i$-th (sender)* index of the receiver, *NOT* the j-th.
  - DO *NOT take $max$* of the entire vector (as in Lamport Vector Clock), rather, only increment the *sender's index* in the local vector
    - Here, we track what which messages are *ACTUALLY DELIVERED* instead of some message you hear about from the sender but haven't actually seen and deliver it.
  - It means that the receiver have *DELIVERED* the messages until $"VC"_"local" [i]$ from the sender.
*NO SOLUTION FOR 7, JUNE 2021*

#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 80, width: 60%),
)


=== Total Ordering (all processes)
Using a *sequence number per group* (instead of per sender) \
==== Sequencer Implementation
Sequencer: A single process assigning numbers
- Sender send the message to the sequencer
- The sequencer multicast the message with the number
- Receivers compare the number to choose whether to deliver the message or put it into the hold-back queue, and request for missing messages if necessary (scalable or basic?)
==== Joint Agreement Implementation
- Each process $i$ keeps
  - $A_i, P_i$ are stored as $("scalar", "PID")$  
  - $A_i = ("scalar", "winner PID")$ the largest agreed sequence number it received so far
  - $P_i = ("scalar", "own PID")$ its own largest proposed number
  - Ordering: $("scalar"_1, "PID"_1) > ("scalar"_2, "PID"_2)$ \
    $<=> ("scalar"_1 > "scalar"_2) or (("scalar"_1 = "scalar"_2) and ("PID"_1 > "PID"_2))$
*Algorithm* (According to the solution of Q7, Jan 2022)\
Idea
- Sender $->$ Receivers: Request their proposed numbers
- Receiver $->$ Sender: Their proposed numbers
- Sender $->$ Receivers: The chosen proposal
*Steps*
+ The *sender* $i$ multicasts message $m$ to *request* for the next 
  + Update its own proposed value $P_i <- (max(P_i."scalar", A_i."scalar"), i)$
  + Add to the hold-back queue with the updated $P_i$: ${m, {"Proposed", P_i}}$ where $P_i$ is a tuple
  + DO NOT include anything to the message (just sequence number request and the message, no $P_i$, the receivers don't need to know?)
+ When receiving the *request* message, each *receiver* $j$ replies their own *proposed* seq number queue the message
  + set the message's (local) sequence number as $P_j <- (max(A_j."scalar", P_j."scalar") + 1, j)$
  + Push it into the push-back queue as ${m, {"Proposed", P_j}$
+ The *sender* selects the largest of (*all proposals* $N$ AND *its own* $P_i$) as the agreed number for $m$ (blocking until all proposals arrive) and multicast the *agreement*
  + $N = (max({forall j in "Receivers": P_j} union {P_i}), "argmax"({forall j in "Receivers": P_j} union {P_i}))$
  + Update the sequence number of $m$ to $N$ in its own hold-back queue and sort the queue
  + deliver all deliverable messages
+ When receiving the *agreement message*, each *receiver* $j$ 
  + updates $A_j <- (max(A_j."scalar", N."scalar"), A_j."scalar" >= N."scalar" ? j : N."PID")$
  + Update the sequence number of $m$ to $N$ in its own hold-back queue and *sort the queue*
  + deliver all deliverable messages
+ *Deliverable messages*: Messages are delivered when it is at the *front of the queue and the number is agreed*.
* NO SOLUTION FOR 5, JAN 2025 *

== Atomic Multicast (View-synchronous Multicast / Virtual Synchrony)
With *FAULTY* processes\
- Guarantee that a message is delivered to either *ALL* processes or none at all
- Delivered ONLY to the non-faulty members of the group
  - Processes have to agree on the current membership

Each message is associated with a view group: a message *belongs to* a view.

Different processes can change their view at different time (postpone the view change if necessary)

*Important*
- If a correct process delivers message in view $V$, the all other processes in view $V+1$ must also deliver $m$.
  + Sender crashes before sending $m$, no one received it $=>$ alright
  + Sender sends $m$ and crashes, one node delivered it
    - Other nodes must exchange $m$ among themselves and *deliver* $m$ *before* they are allowed to install the *new* view
- View change messages must be delivered in *total order* (sequencer or joint agreement)

*Normal Operations* (within a view)
- Append the view number to multicast messages
- Check the message's view number when receiving
  - $m."View" > "View"_"local"$: queue the message until the matching view is installed
  - $m."View" = "View"_"local"$: deliver the message according to the specified multicast ordering
  - $m."View" < "View"_"local"$: discard message

*View Change*\
A *Flush* operation is triggered when a process $P$ receives a *view change* message
+ Temporarily stop sending (from application) multicast messages
+ Forward to *$forall P_i in "View"$* all the messages $P$ has *delivered*
  - As all processes in the view are doing this, we can make sure the we have the full set of the messages
+ If a process $P$ discovered a new (missing) message from process $Q in "View"_"current" inter "View"_"new"$ (belongs to the current view), the process delivers this message
+ After received *ALL* the forwarded messages from *ALL* the processes ($Q in "View"_"current" inter "View"_"new"$) in the current view
  - Change the view (i.e. install new view)
  - Allow the application to resume multicasting messages

#figure(
  image("../slides/2-distributed-algorithms.pdf", page: 95, width: 60%)
)