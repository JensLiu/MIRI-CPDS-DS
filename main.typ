// =================== COVER ========================
#set page(numbering: none)
#align(horizon + left)[
  #text(size: 24pt, "Notes for Distributed Systems")\
  
  #text("MIRI-CPDS")
  #v(2em)
  #text(size: 18pt, "Yuechao Liu")\
  #text(size: 12pt, [Universitat Politècnica de Catalunya])
]
#align(bottom + left)[#datetime.today().display()]
#pagebreak()

// =================== OUTLINE ========================
#set document(title: "Distributed Systems", author: "Yuechao Liu")
#set page(
  header: [
    _Notes for Distributed Systems_
    #h(1fr)
    Yuechao Liu
  ],
  numbering: "1"
)

#outline()
#pagebreak()

// ================== TEXTS =======================
#set math.equation(numbering: "(1)")
#set math.mat(delim: "[")
#set math.vec(delim: "[")
#set heading(numbering: "1.1")
#show heading.where(level: 1): set text(size: 19pt)
#show heading.where(level: 2): set text(size: 17pt)
#show heading.where(level: 3): set text(size: 15pt)
#show heading.where(level: 4): set text(size: 13pt)

#include "sections/basic-concepts.typ"
#include "sections/global-time.typ"
#include "sections/global-state.typ"
#include "sections/election.typ"
#include "sections/multicast.typ"
#include "sections/consensus.typ"
#include "sections/concurrency.typ"
#include "sections/consistency.typ"

  


